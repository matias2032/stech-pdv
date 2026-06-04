package com.stechengenharia.pdv_backend.categoria.sync;

import com.stechengenharia.pdv_backend.categoria.sync.CategoriaSyncDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CategoriaSyncCloudService {

    private final CloudCategoriaRepository categoriaRepository; // <-- tipo correto

    @Transactional
    public void aplicarLote(List<CategoriaSyncDTO> dtos) {
        for (CategoriaSyncDTO dto : dtos) {

            CloudCategoriaEntity cloud = categoriaRepository.findById(dto.idCategoria())
                    .orElse(new CloudCategoriaEntity());

            if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Categoria] Conflito de versão id={} — ignorado", dto.idCategoria());
                continue;
            }

            if ("PENDING_DELETE".equals(dto.syncStatus())) {
                cloud.setDeleted(true);
            } else {
                cloud.setNomeCategoria(dto.nomeCategoria());
                cloud.setDescricao(dto.descricao());
                cloud.setDeleted(dto.deleted());
            }

            // Garante que o ID fica atribuído nos registos novos
            cloud.setIdCategoria(dto.idCategoria());
            cloud.setVersion(dto.version());
            cloud.setSyncStatus("SYNCED");
            cloud.setUpdatedAt(dto.updatedAt());
            categoriaRepository.save(cloud);
        }
    }

    @Transactional(readOnly = true)
    public List<CategoriaSyncDTO> listarDesde(Instant since) {
        return categoriaRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(c -> new CategoriaSyncDTO(
                        c.getIdCategoria(),
                        c.getNomeCategoria(),
                        c.getDescricao(),
                        c.getSyncStatus(),
                        c.isDeleted(),
                        c.getVersion(),
                        c.getUpdatedAt()))
                .toList();
    }
}