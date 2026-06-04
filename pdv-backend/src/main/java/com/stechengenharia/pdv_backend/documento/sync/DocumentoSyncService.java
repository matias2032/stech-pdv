package com.stechengenharia.pdv_backend.documento.sync;

import com.stechengenharia.pdv_backend.documento.entity.DocumentoFiscal;
import com.stechengenharia.pdv_backend.documento.repository.DocumentoFiscalRepository;
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
public class DocumentoSyncService {

    private final DocumentoFiscalRepository documentoRepository;
    private final RestTemplate restTemplate;

    @Value("${sync.cloud.base-url}") private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")  private String apiKey;

    private Instant lastPullAt = Instant.EPOCH;

    @Transactional
    public void push() {
        List<DocumentoFiscal> pendentes = documentoRepository.findBySyncStatusIn(
            List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
        );
        if (pendentes.isEmpty()) return;
        log.info("[Documento PUSH] {} registos pendentes", pendentes.size());

        try {
            List<DocumentoSyncDTO> payload = pendentes.stream().map(this::toDTO).toList();
            ResponseEntity<Void> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/documentos", HttpMethod.POST,
                new HttpEntity<>(payload, buildHeaders()), Void.class
            );
            if (resp.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(d -> d.setSyncStatus("SYNCED"));
                documentoRepository.saveAll(pendentes);
                log.info("[Documento PUSH] {} registos marcados SYNCED", pendentes.size());
            }
        } catch (Exception e) {
            log.warn("[Documento PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    // PULL é somente leitura — documentos fiscais são emitidos na loja,
    // a nuvem apenas os recebe. Só faz sentido puxar anulações feitas remotamente.
    @Transactional
    public void pull() {
        log.debug("[Documento PULL] Buscando desde {}", lastPullAt);
        try {
            ResponseEntity<List<DocumentoSyncDTO>> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/documentos?since=" + lastPullAt,
                HttpMethod.GET, new HttpEntity<>(buildHeaders()),
                new ParameterizedTypeReference<>() {}
            );
            if (resp.getBody() == null || resp.getBody().isEmpty()) return;

            for (DocumentoSyncDTO dto : resp.getBody()) {
                // Só aplica anulações vindas da nuvem — nunca sobrescreve emissões locais
                documentoRepository.findById(dto.idDocumento()).ifPresent(local -> {
                    if (local.getVersion() != null && dto.version() < local.getVersion()) return;
                    if (Boolean.TRUE.equals(dto.anulado()) && !Boolean.TRUE.equals(local.getAnulado())) {
                        local.setAnulado(true);
                        local.setMotivoAnulacao(dto.motivoAnulacao());
                        local.setSyncStatus("SYNCED");
                        documentoRepository.save(local);
                    }
                });
            }
            lastPullAt = Instant.now();
        } catch (Exception e) {
            log.warn("[Documento PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    private DocumentoSyncDTO toDTO(DocumentoFiscal d) {
        return new DocumentoSyncDTO(
            d.getId(),
            d.getTipoDocumento().getId(),
            d.getIdPedido(),
            d.getReferencia(),
            d.getNumeroSeq(),
            d.getAno(),
            d.getCodigoAt(),
            d.getUsuario().getId(),
            d.getEmitidoEm(),
            d.getAnulado(),
            d.getMotivoAnulacao(),
            d.getSyncStatus(),
            d.isDeleted(),
            d.getVersion(),
            d.getUpdatedAt()
        );
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}