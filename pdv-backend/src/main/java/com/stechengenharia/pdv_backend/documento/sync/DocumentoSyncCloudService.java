package com.stechengenharia.pdv_backend.documento.sync;

import com.stechengenharia.pdv_backend.documento.sync.DocumentoSyncDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class DocumentoSyncCloudService {

    private final CloudDocumentoRepository documentoRepository;

    @Transactional
    public void aplicarLote(List<DocumentoSyncDTO> dtos) {
        for (DocumentoSyncDTO dto : dtos) {
            CloudDocumentoEntity cloud = documentoRepository.findById(dto.idDocumento())
                    .orElse(new CloudDocumentoEntity());

            if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Documento] Conflito versão id={} — ignorado", dto.idDocumento());
                continue;
            }

            cloud.setIdDocumento(dto.idDocumento());
            cloud.setIdTipoDocumento(dto.idTipoDocumento());
            cloud.setIdPedido(dto.idPedido());
            cloud.setReferencia(dto.referencia());
            cloud.setNumeroSeq(dto.numeroSeq());
            cloud.setAno(dto.ano());
            cloud.setCodigoAt(dto.codigoAt());
            cloud.setIdUsuario(dto.idUsuario());
            cloud.setEmitidoEm(dto.emitidoEm());
            cloud.setAnulado(dto.anulado());
            cloud.setMotivoAnulacao(dto.motivoAnulacao());
            cloud.setDeleted(dto.deleted());
            cloud.setVersion(dto.version());
            cloud.setSyncStatus("SYNCED");
            cloud.setUpdatedAt(dto.updatedAt());
            documentoRepository.save(cloud);
        }
    }

    @Transactional(readOnly = true)
    public List<DocumentoSyncDTO> listarDesde(Instant since) {
        return documentoRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(d -> new DocumentoSyncDTO(
                        d.getIdDocumento(), d.getIdTipoDocumento(), d.getIdPedido(),
                        d.getReferencia(), d.getNumeroSeq(), d.getAno(), d.getCodigoAt(),
                        d.getIdUsuario(), d.getEmitidoEm(), d.getAnulado(),
                        d.getMotivoAnulacao(), d.getSyncStatus(),
                        d.isDeleted(), d.getVersion(), d.getUpdatedAt()))
                .toList();
    }
}