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
import com.stechengenharia.pdv_backend.pedido.entity.PedidoCreditoParcela;
import com.stechengenharia.pdv_backend.pedido.entity.PedidoCreditoPagamento;
import com.stechengenharia.pdv_backend.pedido.repository.PedidoCreditoParcelaRepository;
import com.stechengenharia.pdv_backend.pedido.repository.PedidoCreditoPagamentoRepository;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PedidoSyncService {

    private final PedidoRepository pedidoRepository;
private final PedidoCreditoParcelaRepository parcelaRepository;
private final PedidoCreditoPagamentoRepository pagamentoCreditoRepository;
private final RestTemplate restTemplate;

    @Value("${sync.cloud.base-url}") private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")  private String apiKey;

    private Instant lastPullAt = Instant.EPOCH;

@Transactional
public void push() {
    pushPedidos();
    pushParcelas();
    pushPagamentosCredito();
}

private void pushPedidos() {
    List<Pedido> pendentes = pedidoRepository.findBySyncStatusIn(
        List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
    );

    if (pendentes.isEmpty()) return;

    log.info("[Pedido PUSH] {} registos pendentes", pendentes.size());

    try {
        List<PedidoSyncDTO> payload = pendentes.stream().map(this::toDTO).toList();

        ResponseEntity<Void> resp = restTemplate.exchange(
            cloudBaseUrl + "/sync/pedidos",
            HttpMethod.POST,
            new HttpEntity<>(payload, buildHeaders()),
            Void.class
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

private void pushParcelas() {
    List<PedidoCreditoParcela> pendentes = parcelaRepository.findBySyncStatusIn(
        List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
    );

    if (pendentes.isEmpty()) return;

    log.info("[Parcela PUSH] {} registos pendentes", pendentes.size());

    try {
        List<ParcelaSyncDTO> payload = pendentes.stream()
                .map(this::toParcelaDTO)
                .toList();

        ResponseEntity<Void> resp = restTemplate.exchange(
            cloudBaseUrl + "/sync/parcelas",
            HttpMethod.POST,
            new HttpEntity<>(payload, buildHeaders()),
            Void.class
        );

        if (resp.getStatusCode().is2xxSuccessful()) {
            pendentes.forEach(p -> p.setSyncStatus("SYNCED"));
            parcelaRepository.saveAll(pendentes);
            log.info("[Parcela PUSH] {} registos marcados SYNCED", pendentes.size());
        }
    } catch (Exception e) {
        log.warn("[Parcela PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
    }
}

private void pushPagamentosCredito() {
    List<PedidoCreditoPagamento> pendentes = pagamentoCreditoRepository.findBySyncStatusIn(
        List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
    );

    if (pendentes.isEmpty()) return;

    log.info("[Pagamento Crédito PUSH] {} registos pendentes", pendentes.size());

    try {
        List<PagamentoCreditoSyncDTO> payload = pendentes.stream()
                .map(this::toPagamentoCreditoDTO)
                .toList();

        ResponseEntity<Void> resp = restTemplate.exchange(
            cloudBaseUrl + "/sync/pagamentos-credito",
            HttpMethod.POST,
            new HttpEntity<>(payload, buildHeaders()),
            Void.class
        );

        if (resp.getStatusCode().is2xxSuccessful()) {
            pendentes.forEach(p -> p.setSyncStatus("SYNCED"));
            pagamentoCreditoRepository.saveAll(pendentes);
            log.info("[Pagamento Crédito PUSH] {} registos marcados SYNCED", pendentes.size());
        }
    } catch (Exception e) {
        log.warn("[Pagamento Crédito PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
    }
}

    // Pedidos são gerados na loja — PULL só aplica actualizações de status
    // vindas de outra instância (ex: sede anulando um pedido remotamente)
@Transactional
public void pull() {
    Instant since = lastPullAt;

    pullPedidos(since);
    pullParcelas(since);
    pullPagamentosCredito(since);

    lastPullAt = Instant.now();
}

private void pullPedidos(Instant since) {
    log.debug("[Pedido PULL] Buscando desde {}", since);

    try {
        ResponseEntity<List<PedidoSyncDTO>> resp = restTemplate.exchange(
            cloudBaseUrl + "/sync/pedidos?since=" + since,
            HttpMethod.GET,
            new HttpEntity<>(buildHeaders()),
            new ParameterizedTypeReference<>() {}
        );

        if (resp.getBody() == null || resp.getBody().isEmpty()) return;

        for (PedidoSyncDTO dto : resp.getBody()) {
            pedidoRepository.findById(dto.idPedido()).ifPresent(local -> {
                if (local.getVersion() != null && dto.version() < local.getVersion()) return;

                local.setStatusPedido(dto.statusPedido());
                local.setTipoVenda(dto.tipoVenda());
                local.setModalidadeCredito(dto.modalidadeCredito());
                local.setStatusPagamento(dto.statusPagamento());
                local.setIdDocumentoFacturaCredito(dto.idDocumentoFacturaCredito());
                local.setDataAberturaCredito(dto.dataAberturaCredito());
                local.setDataVencimentoCredito(dto.dataVencimentoCredito());
                local.setDataLiquidacaoCredito(dto.dataLiquidacaoCredito());
                local.setObservacoesCredito(dto.observacoesCredito());
                local.setNomeClienteSingular(dto.nomeClienteSingular());       // ← novo
                local.setApelidoClienteSingular(dto.apelidoClienteSingular());
                local.setDeleted(dto.deleted());
                local.setVersion(dto.version());
                local.setSyncStatus("SYNCED");

                pedidoRepository.save(local);
            });
        }
    } catch (Exception e) {
        log.warn("[Pedido PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
    }
}

private void pullParcelas(Instant since) {
    log.debug("[Parcela PULL] Buscando desde {}", since);

    try {
        ResponseEntity<List<ParcelaSyncDTO>> resp = restTemplate.exchange(
            cloudBaseUrl + "/sync/parcelas?since=" + since,
            HttpMethod.GET,
            new HttpEntity<>(buildHeaders()),
            new ParameterizedTypeReference<>() {}
        );

        if (resp.getBody() == null || resp.getBody().isEmpty()) return;

        for (ParcelaSyncDTO dto : resp.getBody()) {
            Pedido pedido = pedidoRepository.findById(dto.idPedido()).orElse(null);
            if (pedido == null) {
                log.warn("[Parcela PULL] Pedido {} não existe localmente. Parcela {} ignorada.",
                        dto.idPedido(), dto.idParcela());
                continue;
            }

            PedidoCreditoParcela local = parcelaRepository.findById(dto.idParcela())
                    .orElse(new PedidoCreditoParcela());

            if (local.getVersion() != null && dto.version() < local.getVersion()) continue;

            local.setIdParcela(dto.idParcela());
            local.setPedido(pedido);
            local.setNumeroParcela(dto.numeroParcela());
            local.setValorParcela(dto.valorParcela());
            local.setValorPago(dto.valorPago());

            // saldoParcela é GENERATED na BD — não aplicar setter

            local.setDataVencimento(dto.dataVencimento());
            local.setDataPagamento(dto.dataPagamento());
            local.setStatusParcela(dto.statusParcela());
            local.setObservacoes(dto.observacoes());
            local.setDeleted(dto.deleted());
            local.setVersion(dto.version());
            local.setSyncStatus("SYNCED");

            parcelaRepository.save(local);
        }
    } catch (Exception e) {
        log.warn("[Parcela PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
    }
}

private void pullPagamentosCredito(Instant since) {
    log.debug("[Pagamento Crédito PULL] Buscando desde {}", since);

    try {
        ResponseEntity<List<PagamentoCreditoSyncDTO>> resp = restTemplate.exchange(
            cloudBaseUrl + "/sync/pagamentos-credito?since=" + since,
            HttpMethod.GET,
            new HttpEntity<>(buildHeaders()),
            new ParameterizedTypeReference<>() {}
        );

        if (resp.getBody() == null || resp.getBody().isEmpty()) return;

        for (PagamentoCreditoSyncDTO dto : resp.getBody()) {
            Pedido pedido = pedidoRepository.findById(dto.idPedido()).orElse(null);
            if (pedido == null) {
                log.warn("[Pagamento Crédito PULL] Pedido {} não existe localmente. Pagamento {} ignorado.",
                        dto.idPedido(), dto.idPagamentoCredito());
                continue;
            }

            PedidoCreditoPagamento local = pagamentoCreditoRepository.findById(dto.idPagamentoCredito())
                    .orElse(new PedidoCreditoPagamento());

            if (local.getVersion() != null && dto.version() < local.getVersion()) continue;

            local.setIdPagamentoCredito(dto.idPagamentoCredito());
            local.setReferencia(dto.referencia());
            local.setPedido(pedido);

            if (dto.idParcela() != null) {
                parcelaRepository.findById(dto.idParcela()).ifPresent(local::setParcela);
            } else {
                local.setParcela(null);
            }

            local.setIdTipoPagamento(dto.idTipoPagamento());
            local.setIdUsuario(dto.idUsuario());
            local.setIdDocumentoRecibo(dto.idDocumentoRecibo());
            local.setValorPago(dto.valorPago());
            local.setDataPagamento(dto.dataPagamento());
            local.setObservacoes(dto.observacoes());
            local.setDeleted(dto.deleted());
            local.setVersion(dto.version());
            local.setSyncStatus("SYNCED");

            pagamentoCreditoRepository.save(local);
        }
    } catch (Exception e) {
        log.warn("[Pagamento Crédito PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
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

    
p.getNomeClienteSingular(),      // ← novo
    p.getApelidoClienteSingular(),   // ← novo

    p.getTipoVenda(),
    p.getModalidadeCredito(),
    p.getStatusPagamento(),
    p.getIdDocumentoFacturaCredito(),
    p.getDataAberturaCredito(),
    p.getDataVencimentoCredito(),
    p.getDataLiquidacaoCredito(),
    p.getObservacoesCredito(),
    p.getSaldoDevedorCredito(),

    itensProduto, itensServico,
    p.getSyncStatus(), p.isDeleted(), p.getVersion(), p.getUpdatedAt()
);
    }

    private ParcelaSyncDTO toParcelaDTO(PedidoCreditoParcela p) {
    return new ParcelaSyncDTO(
            p.getIdParcela(),
            p.getPedido().getIdPedido(),
            p.getNumeroParcela(),
            p.getValorParcela(),
            p.getValorPago(),
            p.getSaldoParcela(),
            p.getDataVencimento(),
            p.getDataPagamento(),
            p.getStatusParcela(),
            p.getObservacoes(),
            p.getSyncStatus(),
            p.isDeleted(),
            p.getVersion(),
            p.getCreatedAt(),
            p.getUpdatedAt()
    );
}

private PagamentoCreditoSyncDTO toPagamentoCreditoDTO(PedidoCreditoPagamento p) {
    return new PagamentoCreditoSyncDTO(
            p.getIdPagamentoCredito(),
            p.getReferencia(),
            p.getPedido().getIdPedido(),
            p.getParcela() != null ? p.getParcela().getIdParcela() : null,
            p.getIdTipoPagamento(),
            p.getIdUsuario(),
            p.getIdDocumentoRecibo(),
            p.getValorPago(),
            p.getDataPagamento(),
            p.getObservacoes(),
            p.getSyncStatus(),
            p.isDeleted(),
            p.getVersion(),
            p.getCreatedAt(),
            p.getUpdatedAt()
    );
}

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}