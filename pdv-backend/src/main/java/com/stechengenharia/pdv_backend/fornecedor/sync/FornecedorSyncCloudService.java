package com.stechengenharia.pdv_backend.fornecedor.sync;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class FornecedorSyncCloudService {

    private final CloudFornecedorRepository fornecedorRepository;

    // ── Recebe lote local → cloud ────────────────────────────────────

    @Transactional
    public void aplicarLote(List<FornecedorSyncDTO> dtos) {
        for (FornecedorSyncDTO dto : dtos) {
            CloudFornecedorEntity cloud = fornecedorRepository.findById(dto.idFornecedor())
                    .orElse(new CloudFornecedorEntity());

            if (cloud.getVersion() != null
                    && dto.version() != null
                    && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Fornecedor] Conflito versão id={} — ignorado", dto.idFornecedor());
                continue;
            }

            cloud.setIdFornecedor(dto.idFornecedor());
            cloud.setDeleted("PENDING_DELETE".equals(dto.syncStatus()) || dto.deleted());

            if (!"PENDING_DELETE".equals(dto.syncStatus())) {
                cloud.setNome(dto.nome());
                cloud.setEmail(dto.email());
                cloud.setNuit(dto.nuit());
                cloud.setContacto(dto.contacto());
                cloud.setMorada(dto.morada());
            }

            cloud.setVersion(dto.version());
            cloud.setSyncStatus("SYNCED");
            cloud.setUpdatedAt(dto.updatedAt());

            fornecedorRepository.save(cloud);
        }
    }

    // ── Lista alterações cloud → local ───────────────────────────────

    @Transactional(readOnly = true)
    public List<FornecedorSyncDTO> listarDesde(Instant since) {
        return fornecedorRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(f -> new FornecedorSyncDTO(
                        f.getIdFornecedor(),
                        f.getNome(),
                        f.getEmail(),
                        f.getNuit(),
                        f.getContacto(),
                        f.getMorada(),
                        f.getSyncStatus(),
                        f.isDeleted(),
                        f.getVersion(),
                        f.getUpdatedAt()
                ))
                .toList();
    }
}