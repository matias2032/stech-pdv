package com.stechengenharia.pdv_backend.despesa.sync;

import com.stechengenharia.pdv_backend.despesa.entity.Despesa;
import com.stechengenharia.pdv_backend.despesa.repository.DespesaRepository;
import com.stechengenharia.pdv_backend.fornecedor.repository.FornecedorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class DespesaSyncService {

    private final DespesaRepository despesaRepository;
    private final FornecedorRepository fornecedorRepository;
    private final RestTemplate restTemplate;

    @Value("${sync.cloud.base-url}")
    private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")
    private String apiKey;

    private Instant lastPullAt = Instant.EPOCH;

    @Transactional
    public void push() {
        List<Despesa> pendentes = despesaRepository.findBySyncStatusIn(
                List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE"));

        if (pendentes.isEmpty())
            return;

        log.info("[Despesa PUSH] {} registos pendentes", pendentes.size());

        try {
            List<DespesaSyncDTO> payload = pendentes.stream()
                    .map(this::toDTO)
                    .toList();

            ResponseEntity<Void> resp = restTemplate.exchange(
                    cloudBaseUrl + "/sync/despesas",
                    HttpMethod.POST,
                    new HttpEntity<>(payload, buildHeaders()),
                    Void.class);

            if (resp.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(d -> d.setSyncStatus("SYNCED"));
                despesaRepository.saveAll(pendentes);
                log.info("[Despesa PUSH] {} registos marcados SYNCED", pendentes.size());
            }

        } catch (Exception e) {
            log.warn("[Despesa PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    @Transactional
    public void pull() {
        log.debug("[Despesa PULL] Buscando desde {}", lastPullAt);

        try {
            ResponseEntity<List<DespesaSyncDTO>> resp = restTemplate.exchange(
                    cloudBaseUrl + "/sync/despesas?since=" + lastPullAt,
                    HttpMethod.GET,
                    new HttpEntity<>(buildHeaders()),
                    new ParameterizedTypeReference<>() {
                    });

            if (resp.getBody() == null || resp.getBody().isEmpty())
                return;

            for (DespesaSyncDTO dto : resp.getBody()) {
                aplicarDTO(dto);
            }

            lastPullAt = Instant.now();

        } catch (Exception e) {
            log.warn("[Despesa PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    private void aplicarDTO(DespesaSyncDTO dto) {
        Despesa despesa = despesaRepository.findById(dto.idDespesa())
                .orElse(new Despesa());

        if (despesa.getVersion() != null && dto.version() < despesa.getVersion()) {
            log.warn("[Despesa PULL] Conflito versão id={} — ignorado", dto.idDespesa());
            return;
        }

        despesa.setIdDespesa(dto.idDespesa());
        despesa.setDescricao(dto.descricao());
        despesa.setValorGasto(dto.valorGasto());
        despesa.setDataDespesa(dto.dataDespesa());
        despesa.setDeleted(dto.deleted());
        despesa.setSyncStatus("SYNCED");

        if (dto.idFornecedor() != null) {
            fornecedorRepository.findByIdAtivo(dto.idFornecedor())
                    .ifPresent(despesa::setFornecedor);
        } else {
            despesa.setFornecedor(null);
        }

        despesaRepository.save(despesa);
    }

    private DespesaSyncDTO toDTO(Despesa d) {
        return new DespesaSyncDTO(
                d.getIdDespesa(),
                d.getFornecedor() != null ? d.getFornecedor().getId() : null,
                d.getDescricao(),
                d.getValorGasto(),
                d.getDataDespesa(),
                d.getSyncStatus(),
                d.isDeleted(),
                d.getVersion(),
                d.getUpdatedAt());
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}