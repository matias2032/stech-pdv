package com.stechengenharia.pdv_backend.categoria.sync;

import com.stechengenharia.pdv_backend.categoria.entity.Categoria;
import com.stechengenharia.pdv_backend.categoria.repository.CategoriaRepository;
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
public class CategoriaSyncService {

    private final CategoriaRepository categoriaRepository;
    private final RestTemplate restTemplate;

    @Value("${sync.cloud.base-url}") private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")  private String apiKey;

    private Instant lastPullAt = Instant.EPOCH; // era OffsetDateTime.now().minusYears(10)

    // push() — sem alterações
    public void push() {
        List<Categoria> pendentes = categoriaRepository.findBySyncStatusIn(
            List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
        );
        if (pendentes.isEmpty()) return;

        try {
            List<CategoriaSyncDTO> payload = pendentes.stream().map(this::toDTO).toList();
            HttpHeaders headers = buildHeaders();
            ResponseEntity<Void> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/categorias", HttpMethod.POST,
                new HttpEntity<>(payload, headers), Void.class
            );
            if (resp.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(c -> c.setSyncStatus("SYNCED"));
                categoriaRepository.saveAll(pendentes);
            }
        } catch (Exception e) {
            log.warn("[Categoria PUSH] Falhou: {}", e.getMessage());
        }
    }

    @Transactional
    public void pull() {
        try {
            ResponseEntity<List<CategoriaSyncDTO>> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/categorias?since=" + lastPullAt,
                HttpMethod.GET, new HttpEntity<>(buildHeaders()),
                new ParameterizedTypeReference<>() {}
            );
            if (resp.getBody() == null) return;

            for (CategoriaSyncDTO dto : resp.getBody()) {
                Categoria local = categoriaRepository.findById(dto.idCategoria())
                        .orElse(new Categoria());
                // Versão local mais recente → nuvem está desatualizada, ignorar
                if (local.getVersion() != null && dto.version() < local.getVersion()) continue;

                local.setNomeCategoria(dto.nomeCategoria());
                local.setDescricao(dto.descricao());
                local.setDeleted(dto.deleted());
                local.setVersion(dto.version());
                local.setSyncStatus("SYNCED");
                categoriaRepository.save(local);
            }
            lastPullAt = Instant.now();
        } catch (Exception e) {
            log.warn("[Categoria PULL] Falhou: {}", e.getMessage());
        }
    }

    private CategoriaSyncDTO toDTO(Categoria c) {
        return new CategoriaSyncDTO(
            c.getIdCategoria(), c.getNomeCategoria(),
            c.getDescricao(), c.getSyncStatus(),
            c.isDeleted(), c.getVersion(),
            c.getUpdatedAt()   // agora Instant — compila sem cast
        );
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}