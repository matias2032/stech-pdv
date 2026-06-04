package com.stechengenharia.pdv_backend.marca.sync;

import com.stechengenharia.pdv_backend.marca.entity.Marca;
import com.stechengenharia.pdv_backend.marca.repository.MarcaRepository;
// era: import com.stechengenharia.pdv_backend.marca.sync.dto.MarcaSyncDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;  // era OffsetDateTime
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MarcaSyncService {

    private final MarcaRepository marcaRepository;
    private final RestTemplate restTemplate;

    @Value("${sync.cloud.base-url}") private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")  private String apiKey;

    private Instant lastPullAt = Instant.EPOCH; // era OffsetDateTime.now().minusYears(10)

    @Transactional
    public void push() {
        List<Marca> pendentes = marcaRepository.findBySyncStatusIn(
            List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
        );
        if (pendentes.isEmpty()) return;
        log.info("[Marca PUSH] {} registos pendentes", pendentes.size());

        List<MarcaSyncDTO> payload = pendentes.stream().map(this::toSyncDTO).toList();
        try {
            ResponseEntity<Void> response = restTemplate.exchange(
                cloudBaseUrl + "/sync/marcas", HttpMethod.POST,
                new HttpEntity<>(payload, buildHeaders()), Void.class
            );
            if (response.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(m -> m.setSyncStatus("SYNCED"));
                marcaRepository.saveAll(pendentes);
                log.info("[Marca PUSH] {} registos marcados como SYNCED", pendentes.size());
            }
        } catch (Exception e) {
            log.warn("[Marca PUSH] Falhou: {}. Próxima tentativa em 60s.", e.getMessage());
        }
    }

    @Transactional
    public void pull() {
        log.debug("[Marca PULL] Buscando actualizações desde {}", lastPullAt);
        try {
            ResponseEntity<List<MarcaSyncDTO>> response = restTemplate.exchange(
                cloudBaseUrl + "/sync/marcas?since=" + lastPullAt,
                HttpMethod.GET, new HttpEntity<>(buildHeaders()),
                new ParameterizedTypeReference<>() {}
            );
            if (!response.getStatusCode().is2xxSuccessful()
                    || response.getBody() == null
                    || response.getBody().isEmpty()) return;

            for (MarcaSyncDTO dto : response.getBody()) {
                Marca local = marcaRepository.findById(dto.idMarca()).orElse(new Marca());
                if (local.getVersion() != null && dto.version() < local.getVersion()) continue;

                local.setNomeMarca(dto.nomeMarca());
                local.setDeleted(dto.deleted());
                local.setVersion(dto.version());
                local.setSyncStatus("SYNCED");
                marcaRepository.save(local);
            }
            lastPullAt = Instant.now(); // era OffsetDateTime.now()
        } catch (Exception e) {
            log.warn("[Marca PULL] Falhou: {}. Próxima tentativa em 60s.", e.getMessage());
        }
    }

    private MarcaSyncDTO toSyncDTO(Marca m) {
        return new MarcaSyncDTO(
            m.getIdMarca(), m.getNomeMarca(),
            m.getSyncStatus(), m.isDeleted(),
            m.getVersion(), m.getUpdatedAt()
        );
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}