package com.stechengenharia.pdv_backend.produto.sync;

import com.stechengenharia.pdv_backend.produto.entity.Produto;
import com.stechengenharia.pdv_backend.produto.repository.ProdutoRepository;
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
public class ProdutoSyncService {

    private final ProdutoRepository produtoRepository;
    private final RestTemplate restTemplate;

    @Value("${sync.cloud.base-url}") private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")  private String apiKey;

    private Instant lastPullAt = Instant.EPOCH;

    @Transactional
    public void push() {
        List<Produto> pendentes = produtoRepository.findBySyncStatusIn(
            List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
        );
        if (pendentes.isEmpty()) return;
        log.info("[Produto PUSH] {} registos pendentes", pendentes.size());

        try {
            List<ProdutoSyncDTO> payload = pendentes.stream().map(this::toDTO).toList();
            ResponseEntity<Void> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/produtos", HttpMethod.POST,
                new HttpEntity<>(payload, buildHeaders()), Void.class
            );
            if (resp.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(p -> p.setSyncStatus("SYNCED"));
                produtoRepository.saveAll(pendentes);
                log.info("[Produto PUSH] {} registos marcados SYNCED", pendentes.size());
            }
        } catch (Exception e) {
            log.warn("[Produto PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    @Transactional
    public void pull() {
        log.debug("[Produto PULL] Buscando desde {}", lastPullAt);
        try {
            ResponseEntity<List<ProdutoSyncDTO>> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/produtos?since=" + lastPullAt,
                HttpMethod.GET, new HttpEntity<>(buildHeaders()),
                new ParameterizedTypeReference<>() {}
            );
            if (resp.getBody() == null || resp.getBody().isEmpty()) return;

            for (ProdutoSyncDTO dto : resp.getBody()) {
                Produto local = produtoRepository.findById(dto.idProduto())
                        .orElse(new Produto());
                if (local.getVersion() != null && dto.version() < local.getVersion()) continue;

                local.setNomeProduto(dto.nomeProduto());
                local.setDescricao(dto.descricao());
                local.setPreco(dto.preco());
                local.setPrecoPromocional(dto.precoPromocional());
                local.setQuantidadeEstoque(dto.quantidadeEstoque());
                local.setAtivo(dto.ativo());
                local.setDeleted(dto.deleted());
                local.setVersion(dto.version());
                local.setSyncStatus("SYNCED");
                produtoRepository.save(local);
            }
            lastPullAt = Instant.now();
        } catch (Exception e) {
            log.warn("[Produto PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    private ProdutoSyncDTO toDTO(Produto p) {
        return new ProdutoSyncDTO(
            p.getIdProduto(), p.getNomeProduto(), p.getDescricao(),
            p.getPreco(), p.getPrecoPromocional(), p.getQuantidadeEstoque(),
            p.getAtivo(), p.getSyncStatus(), p.isDeleted(),
            p.getVersion(), p.getUpdatedAt()
        );
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}