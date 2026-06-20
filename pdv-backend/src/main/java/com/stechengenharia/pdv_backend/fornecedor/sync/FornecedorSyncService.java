package com.stechengenharia.pdv_backend.fornecedor.sync;

import com.stechengenharia.pdv_backend.fornecedor.entity.Fornecedor;
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
public class FornecedorSyncService {

    private final FornecedorRepository fornecedorRepository;
    private final RestTemplate         restTemplate;

    @Value("${sync.cloud.base-url}")
    private String cloudBaseUrl;

    @Value("${sync.cloud.api-key}")
    private String apiKey;

    private Instant lastPullAt = Instant.EPOCH;

    // ── PUSH local → nuvem ───────────────────────────────────────────

    @Transactional
    public void push() {
        List<Fornecedor> pendentes = fornecedorRepository.findBySyncStatusIn(
                List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
        );

        if (pendentes.isEmpty()) return;

        log.info("[Fornecedor PUSH] {} registos pendentes", pendentes.size());

        try {
            List<FornecedorSyncDTO> payload = pendentes.stream()
                    .map(this::toDTO)
                    .toList();

            ResponseEntity<Void> resp = restTemplate.exchange(
                    cloudBaseUrl + "/sync/fornecedores",
                    HttpMethod.POST,
                    new HttpEntity<>(payload, buildHeaders()),
                    Void.class
            );

            if (resp.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(f -> f.setSyncStatus("SYNCED"));
                fornecedorRepository.saveAll(pendentes);

                log.info("[Fornecedor PUSH] {} registos marcados SYNCED", pendentes.size());
            }

        } catch (Exception e) {
            log.warn("[Fornecedor PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    // ── PULL nuvem → local ───────────────────────────────────────────

    @Transactional
    public void pull() {
        log.debug("[Fornecedor PULL] Buscando desde {}", lastPullAt);

        try {
            ResponseEntity<List<FornecedorSyncDTO>> resp = restTemplate.exchange(
                    cloudBaseUrl + "/sync/fornecedores?since=" + lastPullAt,
                    HttpMethod.GET,
                    new HttpEntity<>(buildHeaders()),
                    new ParameterizedTypeReference<>() {}
            );

            if (resp.getBody() == null || resp.getBody().isEmpty()) return;

            for (FornecedorSyncDTO dto : resp.getBody()) {
                Fornecedor local = fornecedorRepository.findById(dto.idFornecedor())
                        .orElse(null);

                // Se existe localmente e a versão local é mais recente, ignora
                if (local != null
                        && local.getVersion() != null
                        && dto.version() != null
                        && dto.version() < local.getVersion()) {
                    continue;
                }

                if (local == null) {
                    local = Fornecedor.builder()
                            .nome(dto.nome())
                            .email(dto.email())
                            .nuit(dto.nuit())
                            .contacto(dto.contacto())
                            .morada(dto.morada())
                            .syncStatus("SYNCED")
                            .deleted(dto.deleted())
                            .version(dto.version())
                            .build();

                    fornecedorRepository.save(local);
                    continue;
                }

                local.setNome(dto.nome());
                local.setEmail(dto.email());
                local.setNuit(dto.nuit());
                local.setContacto(dto.contacto());
                local.setMorada(dto.morada());
                local.setDeleted(dto.deleted());
                local.setVersion(dto.version());
                local.setSyncStatus("SYNCED");

                fornecedorRepository.save(local);
            }

            lastPullAt = Instant.now();

        } catch (Exception e) {
            log.warn("[Fornecedor PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    // ── Mapper ───────────────────────────────────────────────────────

    private FornecedorSyncDTO toDTO(Fornecedor f) {
        return new FornecedorSyncDTO(
                f.getId(),
                f.getNome(),
                f.getEmail(),
                f.getNuit(),
                f.getContacto(),
                f.getMorada(),
                f.getSyncStatus(),
                f.isDeleted(),
                f.getVersion(),
                f.getUpdatedAt()
        );
    }

    // ── Headers ──────────────────────────────────────────────────────

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}