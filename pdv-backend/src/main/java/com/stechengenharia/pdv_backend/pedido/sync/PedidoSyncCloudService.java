package com.stechengenharia.pdv_backend.pedido.sync;

import com.stechengenharia.pdv_backend.pedido.sync.PedidoSyncDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PedidoSyncCloudService {

private final CloudPedidoRepository pedidoRepository;
private final CloudParcelaRepository parcelaRepository;
private final CloudPagamentoCreditoRepository pagamentoCreditoRepository;

    @Transactional
    public void aplicarLote(List<PedidoSyncDTO> dtos) {
        for (PedidoSyncDTO dto : dtos) {
            CloudPedidoEntity cloud = pedidoRepository.findById(dto.idPedido())
                    .orElse(new CloudPedidoEntity());

            if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Pedido] Conflito versão id={} — ignorado", dto.idPedido());
                continue;
            }

            cloud.setIdPedido(dto.idPedido());
            cloud.setReferencia(dto.referencia());
            cloud.setIdUsuario(dto.idUsuario());
            cloud.setIdCliente(dto.idCliente());
            cloud.setIdTipoPagamento(dto.idTipoPagamento());
            cloud.setStatusPedido(dto.statusPedido());
            cloud.setTotal(dto.total());
            cloud.setValorPago(dto.valorPago());
            cloud.setPontoReferencia(dto.pontoReferencia());
            cloud.setObservacoes(dto.observacoes());
            cloud.setDataPedido(dto.dataPedido());
            cloud.setDataFinalizacao(dto.dataFinalizacao());
            cloud.setTipoVenda(dto.tipoVenda());
cloud.setModalidadeCredito(dto.modalidadeCredito());
cloud.setStatusPagamento(dto.statusPagamento());
cloud.setIdDocumentoFacturaCredito(dto.idDocumentoFacturaCredito());
cloud.setDataAberturaCredito(dto.dataAberturaCredito());
cloud.setDataVencimentoCredito(dto.dataVencimentoCredito());
cloud.setDataLiquidacaoCredito(dto.dataLiquidacaoCredito());
cloud.setObservacoesCredito(dto.observacoesCredito());
            cloud.setDeleted(dto.deleted());
            cloud.setVersion(dto.version());
            cloud.setSyncStatus("SYNCED");
            cloud.setUpdatedAt(dto.updatedAt());
            pedidoRepository.save(cloud);
        }
    }

    @Transactional(readOnly = true)
    public List<PedidoSyncDTO> listarDesde(Instant since) {
        return pedidoRepository.findByUpdatedAtAfter(since)
                .stream()
        .map(p -> new PedidoSyncDTO(
        p.getIdPedido(), p.getReferencia(), p.getIdUsuario(), p.getIdCliente(),
        p.getIdTipoPagamento(), p.getStatusPedido(), p.getTotal(), p.getValorPago(),
        p.getPontoReferencia(), p.getObservacoes(), p.getDataPedido(),
        p.getDataFinalizacao(),

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

        List.of(), List.of(), // itens não viajam no PULL — só estado do pedido
        p.getSyncStatus(), p.isDeleted(), p.getVersion(), p.getUpdatedAt()))
                .toList();
    }

    @Transactional
public void aplicarLoteParcelas(List<ParcelaSyncDTO> dtos) {
    for (ParcelaSyncDTO dto : dtos) {
        CloudParcelaEntity cloud = parcelaRepository.findById(dto.idParcela())
                .orElse(new CloudParcelaEntity());

        if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
            log.warn("[Cloud Parcela] Conflito versão id={} — ignorado", dto.idParcela());
            continue;
        }

        cloud.setIdParcela(dto.idParcela());
        cloud.setIdPedido(dto.idPedido());
        cloud.setNumeroParcela(dto.numeroParcela());
        cloud.setValorParcela(dto.valorParcela());
        cloud.setValorPago(dto.valorPago());

        // saldoParcela é GENERATED na BD — não aplicar setter

        cloud.setDataVencimento(dto.dataVencimento());
        cloud.setDataPagamento(dto.dataPagamento());
        cloud.setStatusParcela(dto.statusParcela());
        cloud.setObservacoes(dto.observacoes());
        cloud.setDeleted(dto.deleted());
        cloud.setVersion(dto.version());
        cloud.setSyncStatus("SYNCED");
        cloud.setCreatedAt(dto.createdAt());
        cloud.setUpdatedAt(dto.updatedAt());

        parcelaRepository.save(cloud);
    }
}

@Transactional(readOnly = true)
public List<ParcelaSyncDTO> listarParcelasDesde(Instant since) {
    return parcelaRepository.findByUpdatedAtAfter(since)
            .stream()
            .map(p -> new ParcelaSyncDTO(
                    p.getIdParcela(),
                    p.getIdPedido(),
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
            ))
            .toList();
}

@Transactional
public void aplicarLotePagamentosCredito(List<PagamentoCreditoSyncDTO> dtos) {
    for (PagamentoCreditoSyncDTO dto : dtos) {
        CloudPagamentoCreditoEntity cloud = pagamentoCreditoRepository
                .findById(dto.idPagamentoCredito())
                .orElse(new CloudPagamentoCreditoEntity());

        if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
            log.warn("[Cloud Pagamento Crédito] Conflito versão id={} — ignorado",
                    dto.idPagamentoCredito());
            continue;
        }

        cloud.setIdPagamentoCredito(dto.idPagamentoCredito());
        cloud.setReferencia(dto.referencia());
        cloud.setIdPedido(dto.idPedido());
        cloud.setIdParcela(dto.idParcela());
        cloud.setIdTipoPagamento(dto.idTipoPagamento());
        cloud.setIdUsuario(dto.idUsuario());
        cloud.setIdDocumentoRecibo(dto.idDocumentoRecibo());
        cloud.setValorPago(dto.valorPago());
        cloud.setDataPagamento(dto.dataPagamento());
        cloud.setObservacoes(dto.observacoes());
        cloud.setDeleted(dto.deleted());
        cloud.setVersion(dto.version());
        cloud.setSyncStatus("SYNCED");
        cloud.setCreatedAt(dto.createdAt());
        cloud.setUpdatedAt(dto.updatedAt());

        pagamentoCreditoRepository.save(cloud);
    }
}

@Transactional(readOnly = true)
public List<PagamentoCreditoSyncDTO> listarPagamentosCreditoDesde(Instant since) {
    return pagamentoCreditoRepository.findByUpdatedAtAfter(since)
            .stream()
            .map(p -> new PagamentoCreditoSyncDTO(
                    p.getIdPagamentoCredito(),
                    p.getReferencia(),
                    p.getIdPedido(),
                    p.getIdParcela(),
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
            ))
            .toList();
}
}