package com.stechengenharia.pdv_backend.servico.sync;

import com.stechengenharia.pdv_backend.servico.entity.Servico;
import com.stechengenharia.pdv_backend.servico.repository.ServicoRepository;
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
public class ServicoSyncService {

    private final ServicoRepository servicoRepository;
    private final RestTemplate restTemplate;

    @Value("${sync.cloud.base-url}") private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")  private String apiKey;

    private Instant lastPullAt = Instant.EPOCH;

    @Transactional
    public void push() {
        List<Servico> pendentes = servicoRepository.findBySyncStatusIn(
            List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
        );
        if (pendentes.isEmpty()) return;
        log.info("[Servico PUSH] {} registos pendentes", pendentes.size());

        try {
            List<ServicoSyncDTO> payload = pendentes.stream().map(this::toDTO).toList();
            ResponseEntity<Void> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/servicos", HttpMethod.POST,
                new HttpEntity<>(payload, buildHeaders()), Void.class
            );
            if (resp.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(s -> s.setSyncStatus("SYNCED"));
                servicoRepository.saveAll(pendentes);
                log.info("[Servico PUSH] {} registos marcados SYNCED", pendentes.size());
            }
        } catch (Exception e) {
            log.warn("[Servico PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    @Transactional
    public void pull() {
        log.debug("[Servico PULL] Buscando desde {}", lastPullAt);
        try {
            ResponseEntity<List<ServicoSyncDTO>> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/servicos?since=" + lastPullAt,
                HttpMethod.GET, new HttpEntity<>(buildHeaders()),
                new ParameterizedTypeReference<>() {}
            );
            if (resp.getBody() == null || resp.getBody().isEmpty()) return;

            for (ServicoSyncDTO dto : resp.getBody()) {
                Servico local = servicoRepository.findById(dto.idServico())
                        .orElse(new Servico());
                if (local.getVersion() != null && dto.version() < local.getVersion()) continue;

                local.setNomeServico(dto.nomeServico());
                local.setDescricao(dto.descricao());
                local.setPrecoUnitario(dto.precoUnitario());
                local.setUnidade(dto.unidade());
                local.setAtivo(dto.ativo());
                local.setDeleted(dto.deleted());
                local.setVersion(dto.version());
                local.setSyncStatus("SYNCED");
                servicoRepository.save(local);
            }
            lastPullAt = Instant.now();
        } catch (Exception e) {
            log.warn("[Servico PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    private ServicoSyncDTO toDTO(Servico s) {
        return new ServicoSyncDTO(
            s.getIdServico(), s.getNomeServico(), s.getDescricao(),
            s.getPrecoUnitario(), s.getUnidade(), s.getAtivo(),
            s.getSyncStatus(), s.isDeleted(), s.getVersion(), s.getUpdatedAt()
        );
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}