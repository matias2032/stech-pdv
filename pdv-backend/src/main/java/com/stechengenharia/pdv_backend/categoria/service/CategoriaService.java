package com.stechengenharia.pdv_backend.categoria.service;

import com.stechengenharia.pdv_backend.categoria.dto.CategoriaRequestDTO;
import com.stechengenharia.pdv_backend.categoria.dto.CategoriaResponseDTO;
import com.stechengenharia.pdv_backend.categoria.entity.Categoria;
import com.stechengenharia.pdv_backend.categoria.entity.CategoriaMarca;
import com.stechengenharia.pdv_backend.categoria.entity.ProdutoCategoria;
import com.stechengenharia.pdv_backend.categoria.repository.CategoriaMarcaRepository;
import com.stechengenharia.pdv_backend.categoria.repository.CategoriaRepository;
import com.stechengenharia.pdv_backend.categoria.repository.ProdutoCategoriaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class CategoriaService {
    
    private final CategoriaRepository categoriaRepository;
    private final ProdutoCategoriaRepository produtoCategoriaRepository;
    private final CategoriaMarcaRepository categoriaMarcaRepository;
    
    // ===== CRUD BÁSICO =====
    
@Transactional
public CategoriaResponseDTO criar(CategoriaRequestDTO dto) {
    Categoria categoria = new Categoria();
    categoria.setNomeCategoria(dto.getNomeCategoria());
    categoria.setDescricao(dto.getDescricao());
    // syncStatus já vem como PENDING_CREATE do AuditableEntity — linha removida
    return mapToResponseDTO(categoriaRepository.save(categoria));
}

@Transactional
public CategoriaResponseDTO atualizar(Integer id, CategoriaRequestDTO dto) {
    Categoria categoria = categoriaRepository.findByIdCategoriaAndDeletedFalse(id)
            .orElseThrow(() -> new RuntimeException("Categoria não encontrada: " + id));
    categoria.setNomeCategoria(dto.getNomeCategoria());
    categoria.setDescricao(dto.getDescricao());
    return mapToResponseDTO(categoriaRepository.save(categoria));
}

@Transactional
public void deletar(Integer id) {
    Categoria categoria = categoriaRepository.findByIdCategoriaAndDeletedFalse(id)
            .orElseThrow(() -> new RuntimeException("Categoria não encontrada: " + id));
    categoria.setDeleted(true);
    categoria.setSyncStatus("PENDING_DELETE");
    categoriaRepository.save(categoria);
}

@Transactional(readOnly = true)
public List<CategoriaResponseDTO> listar() {
    return categoriaRepository.findByDeletedFalse().stream()
            .map(this::mapToResponseDTO)
            .collect(Collectors.toList());
}

@Transactional(readOnly = true)
public CategoriaResponseDTO buscarPorId(Integer id) {
    return mapToResponseDTO(
        categoriaRepository.findByIdCategoriaAndDeletedFalse(id)
            .orElseThrow(() -> new RuntimeException("Categoria não encontrada: " + id))
    );
}
    // ===== ASSOCIAÇÕES COM PRODUTOS =====
    
    @Transactional
    public void associarProduto(Integer idCategoria, Integer idProduto) {
        log.info("Associando produto {} à categoria {}", idProduto, idCategoria);
        
        // Verificar se a categoria existe
        if (!categoriaRepository.existsById(idCategoria)) {
            throw new RuntimeException("Categoria não encontrada com ID: " + idCategoria);
        }
        
        // Verificar se já existe a associação
        if (produtoCategoriaRepository.existsByIdCategoriaAndIdProduto(idCategoria, idProduto)) {
            log.warn("Associação já existe entre categoria {} e produto {}", idCategoria, idProduto);
            return;
        }
        
        ProdutoCategoria pc = new ProdutoCategoria();
        pc.setIdCategoria(idCategoria);
        pc.setIdProduto(idProduto);
        produtoCategoriaRepository.save(pc);
        
        log.info("Produto {} associado à categoria {} com sucesso", idProduto, idCategoria);
    }
    
    @Transactional
    public void desassociarProduto(Integer idCategoria, Integer idProduto) {
        log.info("Desassociando produto {} da categoria {}", idProduto, idCategoria);
        produtoCategoriaRepository.deleteByIdCategoriaAndIdProduto(idCategoria, idProduto);
        log.info("Produto {} desassociado da categoria {} com sucesso", idProduto, idCategoria);
    }
    
    @Transactional(readOnly = true)
    public List<Integer> listarProdutosDaCategoria(Integer idCategoria) {
        log.info("Listando produtos da categoria: {}", idCategoria);
        return produtoCategoriaRepository.findByIdCategoria(idCategoria)
                .stream()
                .map(ProdutoCategoria::getIdProduto)
                .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public List<Integer> listarCategoriasDoProduto(Integer idProduto) {
        log.info("Listando categorias do produto: {}", idProduto);
        return produtoCategoriaRepository.findByIdProduto(idProduto)
                .stream()
                .map(ProdutoCategoria::getIdCategoria)
                .collect(Collectors.toList());
    }
    
    // ===== ASSOCIAÇÕES COM MARCAS =====
    
    @Transactional
    public void associarMarca(Integer idCategoria, Integer idMarca) {
        log.info("Associando marca {} à categoria {}", idMarca, idCategoria);
        
        // Verificar se a categoria existe
        if (!categoriaRepository.existsById(idCategoria)) {
            throw new RuntimeException("Categoria não encontrada com ID: " + idCategoria);
        }
        
        // Verificar se já existe a associação
        if (categoriaMarcaRepository.existsByIdCategoriaAndIdMarca(idCategoria, idMarca)) {
            log.warn("Associação já existe entre categoria {} e marca {}", idCategoria, idMarca);
            return;
        }
        
        CategoriaMarca cm = new CategoriaMarca();
        cm.setIdCategoria(idCategoria);
        cm.setIdMarca(idMarca);
        categoriaMarcaRepository.save(cm);
        
        log.info("Marca {} associada à categoria {} com sucesso", idMarca, idCategoria);
    }
    
    @Transactional
    public void desassociarMarca(Integer idCategoria, Integer idMarca) {
        log.info("Desassociando marca {} da categoria {}", idMarca, idCategoria);
        categoriaMarcaRepository.deleteByIdCategoriaAndIdMarca(idCategoria, idMarca);
        log.info("Marca {} desassociada da categoria {} com sucesso", idMarca, idCategoria);
    }
    
    @Transactional(readOnly = true)
    public List<Integer> listarMarcasDaCategoria(Integer idCategoria) {
        log.info("Listando marcas da categoria: {}", idCategoria);
        return categoriaMarcaRepository.findByIdCategoria(idCategoria)
                .stream()
                .map(CategoriaMarca::getIdMarca)
                .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public List<Integer> listarCategoriasDaMarca(Integer idMarca) {
        log.info("Listando categorias da marca: {}", idMarca);
        return categoriaMarcaRepository.findByIdMarca(idMarca)
                .stream()
                .map(CategoriaMarca::getIdCategoria)
                .collect(Collectors.toList());
    }
    
    // ===== MÉTODOS AUXILIARES =====
    
  private CategoriaResponseDTO mapToResponseDTO(Categoria categoria) {
    CategoriaResponseDTO dto = new CategoriaResponseDTO();
    dto.setIdCategoria(categoria.getIdCategoria());
    dto.setNomeCategoria(categoria.getNomeCategoria());
    dto.setDescricao(categoria.getDescricao());
    dto.setMarcas(
        categoriaMarcaRepository.findByIdCategoria(categoria.getIdCategoria())
            .stream()
            .map(CategoriaMarca::getIdMarca)
            .collect(Collectors.toList())
    );
    return dto;
}
}