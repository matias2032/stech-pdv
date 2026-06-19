package com.stechengenharia.pdv_backend.cotacao.sync;

import com.stechengenharia.pdv_backend.cotacao.entity.Cotacao;
import com.stechengenharia.pdv_backend.cotacao.repository.CotacaoItemProdutoRepository;
import com.stechengenharia.pdv_backend.cotacao.repository.CotacaoItemServicoRepository;
import com.stechengenharia.pdv_backend.cotacao.repository.CotacaoRepository;
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
public class CotacaoSyncService {

    private final CotacaoRepository              cotacaoRepository;
    private final CotacaoItemProdutoRepository   itemProdutoRepository;
    private final CotacaoItemServicoRepository   itemServicoRepository;
    private final RestTemplate                   restTemplate;

    @Value("${sync.cloud.base-url}") private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")  private String apiKey;

    private Instant lastPullAt = Instant.EPOCH;

    // ════════════════════════════════════════════════════════════════════
    // PUSH — loja → nuvem
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public void push() {
        List<Cotacao> pendentes = cotacaoRepository.findBySyncStatusIn(
                List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
        );
        if (pendentes.isEmpty()) return;
        log.info("[Cotacao PUSH] {} registos pendentes", pendentes.size());

        try {
            List<CotacaoSyncDTO> payload = pendentes.stream()
                    .map(this::toDTO)
                    .toList();

            ResponseEntity<Void> resp = restTemplate.exchange(
                    cloudBaseUrl + "/sync/cotacoes",
                    HttpMethod.POST,
                    new HttpEntity<>(payload, buildHeaders()),
                    Void.class
            );

            if (resp.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(c -> c.setSyncStatus("SYNCED"));
                cotacaoRepository.saveAll(pendentes);
                log.info("[Cotacao PUSH] {} registos marcados SYNCED", pendentes.size());
            }
        } catch (Exception e) {
            log.warn("[Cotacao PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    // ════════════════════════════════════════════════════════════════════
    // PULL — nuvem → loja
    // Aplica apenas mudanças de statusCotacao e deleted
    // Nunca sobrescreve itens locais
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public void pull() {
        log.debug("[Cotacao PULL] Buscando desde {}", lastPullAt);
        try {
            ResponseEntity<List<CotacaoSyncDTO>> resp = restTemplate.exchange(
                    cloudBaseUrl + "/sync/cotacoes?since=" + lastPullAt,
                    HttpMethod.GET,
                    new HttpEntity<>(buildHeaders()),
                    new ParameterizedTypeReference<>() {}
            );

            if (resp.getBody() == null || resp.getBody().isEmpty()) return;

            for (CotacaoSyncDTO dto : resp.getBody()) {
                cotacaoRepository.findById(dto.idCotacao()).ifPresent(local -> {
                    if (local.getVersion() != null && dto.version() < local.getVersion()) return;

                    // só aplica mudanças de estado — nunca sobrescreve itens locais
                    local.setStatusCotacao(dto.statusCotacao());
                            local.setNomeClienteSingular(dto.nomeClienteSingular());        // ← novo
        local.setApelidoClienteSingular(dto.apelidoClienteSingular());  // ← novo
                    local.setDeleted(dto.deleted());
                    local.setVersion(dto.version());
                    local.setSyncStatus("SYNCED");
                    cotacaoRepository.save(local);
                });
            }

            lastPullAt = Instant.now();
            log.debug("[Cotacao PULL] Concluído");
        } catch (Exception e) {
            log.warn("[Cotacao PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    // ════════════════════════════════════════════════════════════════════
    // MAPEAMENTO entity → DTO (com itens embutidos para o PUSH)
    // ════════════════════════════════════════════════════════════════════

    private CotacaoSyncDTO toDTO(Cotacao c) {
        List<CotacaoSyncDTO.ItemProdutoSyncDTO> itensProduto =
                itemProdutoRepository.findByCotacaoId(c.getId())
                        .stream()
                        .map(ip -> new CotacaoSyncDTO.ItemProdutoSyncDTO(
                                ip.getId(),
                                ip.getProduto().getIdProduto(),
                                ip.getQuantidade(),
                                ip.getPrecoUnitario(),
                                ip.getSubtotal(),
                                ip.getObservacoes()
                        ))
                        .toList();
List<CotacaoSyncDTO.ItemServicoSyncDTO> itensServico =
        itemServicoRepository.findByCotacaoId(c.getId())
                .stream()
                .map(is -> new CotacaoSyncDTO.ItemServicoSyncDTO(
                        is.getId(),
                        is.getServico().getIdServico() != null
                                ? is.getServico().getIdServico().longValue()
                                : null,                   // ← converte Integer → Long
                        is.getQuantidade(),
                        is.getPrecoUnitario(),
                        is.getSubtotal(),
                        is.getObservacoes()
                ))
                .toList();

        return new CotacaoSyncDTO(
                c.getId(),
                c.getReferencia(),
                c.getCliente() != null ? c.getCliente().getId() : null,
                 c.getNomeClienteSingular(),       // ← novo
        c.getApelidoClienteSingular(),    // ← novo
                c.getUsuario().getId(),
                c.getStatusCotacao(),
                c.getTotal(),
                c.getValidadeAte(),
                c.getObservacoes(),
                c.getPedidoConvertido() != null ? c.getPedidoConvertido().getIdPedido() : null,
                itensProduto,
                itensServico,
                c.getSyncStatus(),
                c.isDeleted(),
                c.getVersion(),
                c.getUpdatedAt()
        );
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}