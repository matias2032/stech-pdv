package com.stechengenharia.pdv_backend.cotacao.sync;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CotacaoSyncCloudService {

    private final CloudCotacaoRepository cotacaoRepository;

    @Transactional
    public void aplicarLote(List<CotacaoSyncDTO> dtos) {
        for (CotacaoSyncDTO dto : dtos) {
            CloudCotacaoEntity cloud = cotacaoRepository.findById(dto.idCotacao())
                    .orElse(new CloudCotacaoEntity());

            if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Cotacao] Conflito versão id={} — ignorado", dto.idCotacao());
                continue;
            }

            cloud.setIdCotacao(dto.idCotacao());
            cloud.setReferencia(dto.referencia());
            cloud.setIdCliente(dto.idCliente());
            cloud.setIdUsuario(dto.idUsuario());
            cloud.setStatusCotacao(dto.statusCotacao());
            cloud.setTotal(dto.total());
            cloud.setValidadeAte(dto.validadeAte());
            cloud.setObservacoes(dto.observacoes());
            cloud.setIdPedidoConvertido(dto.idPedidoConvertido());
            cloud.setDeleted(dto.deleted());
            cloud.setVersion(dto.version());
            cloud.setSyncStatus("SYNCED");
            cloud.setUpdatedAt(dto.updatedAt());

            cotacaoRepository.save(cloud);
        }
    }

    @Transactional(readOnly = true)
    public List<CotacaoSyncDTO> listarDesde(Instant since) {
        return cotacaoRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(c -> new CotacaoSyncDTO(
                        c.getIdCotacao(),
                        c.getReferencia(),
                        c.getIdCliente(),
                        c.getIdUsuario(),
                        c.getStatusCotacao(),
                        c.getTotal(),
                        c.getValidadeAte(),
                        c.getObservacoes(),
                        c.getIdPedidoConvertido(),
                        List.of(), // itens não viajam no PULL — só estado da cotação
                        List.of(),
                        c.getSyncStatus(),
                        c.isDeleted(),
                        c.getVersion(),
                        c.getUpdatedAt()
                ))
                .toList();
    }
}