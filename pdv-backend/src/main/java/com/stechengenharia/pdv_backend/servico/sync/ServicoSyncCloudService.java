package com.stechengenharia.pdv_backend.servico.sync;

import com.stechengenharia.pdv_backend.servico.sync.ServicoSyncDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ServicoSyncCloudService {

    private final CloudServicoRepository servicoRepository;

    @Transactional
    public void aplicarLote(List<ServicoSyncDTO> dtos) {
        for (ServicoSyncDTO dto : dtos) {
            CloudServicoEntity cloud = servicoRepository.findById(dto.idServico())
                    .orElse(new CloudServicoEntity());

            if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Servico] Conflito versão id={} — ignorado", dto.idServico());
                continue;
            }

            cloud.setIdServico(dto.idServico());
            cloud.setDeleted("PENDING_DELETE".equals(dto.syncStatus()) || dto.deleted());

            if (!"PENDING_DELETE".equals(dto.syncStatus())) {
                cloud.setNomeServico(dto.nomeServico());
                cloud.setDescricao(dto.descricao());
                cloud.setPrecoUnitario(dto.precoUnitario());
                cloud.setUnidade(dto.unidade());
                cloud.setAtivo(dto.ativo());
            }

            cloud.setVersion(dto.version());
            cloud.setSyncStatus("SYNCED");
            cloud.setUpdatedAt(dto.updatedAt());
            servicoRepository.save(cloud);
        }
    }

    @Transactional(readOnly = true)
    public List<ServicoSyncDTO> listarDesde(Instant since) {
        return servicoRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(s -> new ServicoSyncDTO(
                        s.getIdServico(), s.getNomeServico(), s.getDescricao(),
                        s.getPrecoUnitario(), s.getUnidade(), s.getAtivo(),
                        s.getSyncStatus(), s.isDeleted(), s.getVersion(), s.getUpdatedAt()))
                .toList();
    }
}