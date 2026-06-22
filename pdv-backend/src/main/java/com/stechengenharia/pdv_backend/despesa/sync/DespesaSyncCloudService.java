package com.stechengenharia.pdv_backend.despesa.sync;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class DespesaSyncCloudService {

    private final CloudDespesaRepository despesaRepository;

    @Transactional
    public void aplicarLote(List<DespesaSyncDTO> dtos) {
        for (DespesaSyncDTO dto : dtos) {
            CloudDespesaEntity cloud = despesaRepository.findById(dto.idDespesa())
                    .orElse(new CloudDespesaEntity());

            if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Despesa] Conflito versão id={} — ignorado", dto.idDespesa());
                continue;
            }

            cloud.setIdDespesa(dto.idDespesa());
            cloud.setIdFornecedor(dto.idFornecedor());
            cloud.setDescricao(dto.descricao());
            cloud.setValorGasto(dto.valorGasto());
            cloud.setDataDespesa(dto.dataDespesa());
            cloud.setDeleted(dto.deleted());
            cloud.setSyncStatus("SYNCED");
            cloud.setVersion(dto.version());
            cloud.setUpdatedAt(dto.updatedAt());

            despesaRepository.save(cloud);
        }
    }

    @Transactional(readOnly = true)
    public List<DespesaSyncDTO> listarDesde(Instant since) {
        return despesaRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(d -> new DespesaSyncDTO(
                        d.getIdDespesa(),
                        d.getIdFornecedor(),
                        d.getDescricao(),
                        d.getValorGasto(),
                        d.getDataDespesa(),
                        d.getSyncStatus(),
                        d.isDeleted(),
                        d.getVersion(),
                        d.getUpdatedAt()
                ))
                .toList();
    }
}