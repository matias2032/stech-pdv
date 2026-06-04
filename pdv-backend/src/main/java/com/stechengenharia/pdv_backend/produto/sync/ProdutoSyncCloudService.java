package com.stechengenharia.pdv_backend.produto.sync;

import com.stechengenharia.pdv_backend.produto.sync.ProdutoSyncDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProdutoSyncCloudService {

    private final CloudProdutoRepository produtoRepository;

    @Transactional
    public void aplicarLote(List<ProdutoSyncDTO> dtos) {
        for (ProdutoSyncDTO dto : dtos) {
            CloudProdutoEntity cloud = produtoRepository.findById(dto.idProduto())
                    .orElse(new CloudProdutoEntity());

            if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Produto] Conflito versão id={} — ignorado", dto.idProduto());
                continue;
            }

            cloud.setIdProduto(dto.idProduto());
            cloud.setDeleted("PENDING_DELETE".equals(dto.syncStatus()) || dto.deleted());

            if (!"PENDING_DELETE".equals(dto.syncStatus())) {
                cloud.setNomeProduto(dto.nomeProduto());
                cloud.setDescricao(dto.descricao());
                cloud.setPreco(dto.preco());
                cloud.setPrecoPromocional(dto.precoPromocional());
                cloud.setQuantidadeEstoque(dto.quantidadeEstoque());
                cloud.setAtivo(dto.ativo());
            }

            cloud.setVersion(dto.version());
            cloud.setSyncStatus("SYNCED");
            cloud.setUpdatedAt(dto.updatedAt());
            produtoRepository.save(cloud);
        }
    }

    @Transactional(readOnly = true)
    public List<ProdutoSyncDTO> listarDesde(Instant since) {
        return produtoRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(p -> new ProdutoSyncDTO(
                        p.getIdProduto(), p.getNomeProduto(), p.getDescricao(),
                        p.getPreco(), p.getPrecoPromocional(), p.getQuantidadeEstoque(),
                        p.getAtivo(), p.getSyncStatus(), p.isDeleted(),
                        p.getVersion(), p.getUpdatedAt()))
                .toList();
    }
}