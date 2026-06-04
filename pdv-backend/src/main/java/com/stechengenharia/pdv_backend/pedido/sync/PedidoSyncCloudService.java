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
                        List.of(), List.of(), // itens não viajam no PULL — só estado do pedido
                        p.getSyncStatus(), p.isDeleted(), p.getVersion(), p.getUpdatedAt()))
                .toList();
    }
}