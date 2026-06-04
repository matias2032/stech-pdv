package com.stechengenharia.pdv_backend.marca.sync;


import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class MarcaSyncCloudService {

    private final CloudMarcaRepository marcaRepository;

    @Transactional
    public void aplicarLote(List<MarcaSyncDTO> dtos) {
        for (MarcaSyncDTO dto : dtos) {
            CloudMarcaEntity cloud = marcaRepository.findById(dto.idMarca())
                    .orElse(new CloudMarcaEntity());

            if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Marca] Conflito de versão id={} — ignorado", dto.idMarca());
                continue;
            }

            cloud.setIdMarca(dto.idMarca());
            cloud.setDeleted("PENDING_DELETE".equals(dto.syncStatus()) || dto.deleted());
            if (!"PENDING_DELETE".equals(dto.syncStatus())) {
                cloud.setNomeMarca(dto.nomeMarca());
            }
            cloud.setVersion(dto.version());
            cloud.setSyncStatus("SYNCED");
            cloud.setUpdatedAt(dto.updatedAt());
            marcaRepository.save(cloud);
        }
    }

    @Transactional(readOnly = true)
    public List<MarcaSyncDTO> listarDesde(Instant since) {
        return marcaRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(c -> new MarcaSyncDTO(
                        c.getIdMarca(), c.getNomeMarca(),
                        c.getSyncStatus(), c.isDeleted(),
                        c.getVersion(), c.getUpdatedAt()))
                .toList();
    }
}