package com.stechengenharia.pdv_backend.pedido.sync;

import com.stechengenharia.pdv_backend.pedido.entity.Pedido;
import com.stechengenharia.pdv_backend.pedido.repository.PedidoRepository;
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
public class PedidoSyncService {

    private final PedidoRepository pedidoRepository;
    private final RestTemplate     restTemplate;

    @Value("${sync.cloud.base-url}") private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")  private String apiKey;

    private Instant lastPullAt = Instant.EPOCH;

    @Transactional
    public void push() {
        List<Pedido> pendentes = pedidoRepository.findBySyncStatusIn(
            List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
        );
        if (pendentes.isEmpty()) return;
        log.info("[Pedido PUSH] {} registos pendentes", pendentes.size());

        try {
            List<PedidoSyncDTO> payload = pendentes.stream().map(this::toDTO).toList();
            ResponseEntity<Void> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/pedidos", HttpMethod.POST,
                new HttpEntity<>(payload, buildHeaders()), Void.class
            );
            if (resp.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(p -> p.setSyncStatus("SYNCED"));
                pedidoRepository.saveAll(pendentes);
                log.info("[Pedido PUSH] {} registos marcados SYNCED", pendentes.size());
            }
        } catch (Exception e) {
            log.warn("[Pedido PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    // Pedidos são gerados na loja — PULL só aplica actualizações de status
    // vindas de outra instância (ex: sede anulando um pedido remotamente)
    @Transactional
    public void pull() {
        log.debug("[Pedido PULL] Buscando desde {}", lastPullAt);
        try {
            ResponseEntity<List<PedidoSyncDTO>> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/pedidos?since=" + lastPullAt,
                HttpMethod.GET, new HttpEntity<>(buildHeaders()),
                new ParameterizedTypeReference<>() {}
            );
            if (resp.getBody() == null || resp.getBody().isEmpty()) return;

            for (PedidoSyncDTO dto : resp.getBody()) {
                pedidoRepository.findById(dto.idPedido()).ifPresent(local -> {
                    if (local.getVersion() != null && dto.version() < local.getVersion()) return;
                    // Só aplica mudanças de status — nunca sobrescreve itens locais
                    local.setStatusPedido(dto.statusPedido());
                    local.setDeleted(dto.deleted());
                    local.setVersion(dto.version());
                    local.setSyncStatus("SYNCED");
                    pedidoRepository.save(local);
                });
            }
            lastPullAt = Instant.now();
        } catch (Exception e) {
            log.warn("[Pedido PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    private PedidoSyncDTO toDTO(Pedido p) {
        List<PedidoSyncDTO.ItemPedidoSyncDTO> itensProduto = p.getItensProduto().stream()
                .map(i -> new PedidoSyncDTO.ItemPedidoSyncDTO(
                        i.getIdItemPedido(), i.getProduto().getIdProduto(),
                        i.getQuantidade(), i.getPrecoUnitario(), i.getSubtotal()))
                .toList();

        List<PedidoSyncDTO.ItemServicoPedidoSyncDTO> itensServico = p.getItensServico().stream()
                .map(i -> new PedidoSyncDTO.ItemServicoPedidoSyncDTO(
                        i.getIdItemServico(), i.getIdServico(),
                        i.getQuantidade(), i.getPrecoUnitario(),
                        i.getSubtotal(), i.getObservacoes()))
                .toList();

        return new PedidoSyncDTO(
            p.getIdPedido(), p.getReferencia(), p.getIdUsuario(), p.getIdCliente(),
            p.getIdTipoPagamento(), p.getStatusPedido(), p.getTotal(), p.getValorPago(),
            p.getPontoReferencia(), p.getObservacoes(), p.getDataPedido(), p.getDataFinalizacao(),
            itensProduto, itensServico,
            p.getSyncStatus(), p.isDeleted(), p.getVersion(), p.getUpdatedAt()
        );
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}