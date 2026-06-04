package com.stechengenharia.pdv_backend.marca.service;

import com.stechengenharia.pdv_backend.categoria.entity.CategoriaMarca;
import com.stechengenharia.pdv_backend.categoria.repository.CategoriaMarcaRepository;
import com.stechengenharia.pdv_backend.categoria.repository.CategoriaRepository;
import com.stechengenharia.pdv_backend.marca.dto.CategoriaSimplificadaDTO;
import com.stechengenharia.pdv_backend.marca.dto.MarcaComCategoriasDTO;
import com.stechengenharia.pdv_backend.marca.dto.MarcaRequestDTO;
import com.stechengenharia.pdv_backend.marca.dto.MarcaResponseDTO;
import com.stechengenharia.pdv_backend.marca.entity.Marca;
import com.stechengenharia.pdv_backend.marca.repository.MarcaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MarcaService {
    
    private final MarcaRepository marcaRepository;
    private final CategoriaMarcaRepository categoriaMarcaRepository;
    private final CategoriaRepository categoriaRepository;
    
    // ===== CRUD BÁSICO =====
    
 @Transactional
public MarcaResponseDTO criar(MarcaRequestDTO dto) {
    Marca marca = new Marca();
    marca.setNomeMarca(dto.getNomeMarca());
    marca.setSyncStatus("PENDING_CREATE"); // @PrePersist já faz isto, mas explícito é mais seguro
    return mapToResponseDTO(marcaRepository.save(marca));
}

@Transactional
public MarcaResponseDTO atualizar(Integer id, MarcaRequestDTO dto) {
    Marca marca = marcaRepository.findByIdMarcaAndDeletedFalse(id)
            .orElseThrow(() -> new RuntimeException("Marca não encontrada: " + id));
    marca.setNomeMarca(dto.getNomeMarca());
    // @PreUpdate no AuditableEntity muda syncStatus para PENDING_UPDATE automaticamente
    return mapToResponseDTO(marcaRepository.save(marca));
}

@Transactional
public void deletar(Integer id) {
    Marca marca = marcaRepository.findByIdMarcaAndDeletedFalse(id)
            .orElseThrow(() -> new RuntimeException("Marca não encontrada: " + id));
    marca.setDeleted(true);
    marca.setSyncStatus("PENDING_DELETE");
    marcaRepository.save(marca);
}

@Transactional(readOnly = true)
public List<MarcaResponseDTO> listar() {
    return marcaRepository.findByDeletedFalse().stream()
            .map(this::mapToResponseDTO)
            .collect(Collectors.toList());
}

@Transactional(readOnly = true)
public MarcaResponseDTO buscarPorId(Integer id) {
    return mapToResponseDTO(
        marcaRepository.findByIdMarcaAndDeletedFalse(id)
            .orElseThrow(() -> new RuntimeException("Marca não encontrada: " + id))
    );
}
    
    // ===== NOVO MÉTODO - LISTAR MARCAS COM CATEGORIAS =====
    
    @Transactional(readOnly = true)
    public List<MarcaComCategoriasDTO> listarComCategorias() {
        log.info("Listando todas as marcas com categorias");
        
           List<Marca> marcas = marcaRepository.findByDeletedFalse();
        
        return marcas.stream().map(marca -> {
            // Busca as associações da marca
            List<CategoriaMarca> associacoes = 
                categoriaMarcaRepository.findByIdMarca(marca.getIdMarca());
            
            // Busca as categorias completas
            List<CategoriaSimplificadaDTO> categorias = associacoes.stream()
                .map(associacao -> {
                    return categoriaRepository.findById(associacao.getIdCategoria())
                        .map(cat -> new CategoriaSimplificadaDTO(
                            cat.getIdCategoria(),
                            cat.getNomeCategoria()
                        ))
                        .orElse(null);
                })
                .filter(cat -> cat != null)
                .collect(Collectors.toList());
            
            return new MarcaComCategoriasDTO(
                marca.getIdMarca(),
                marca.getNomeMarca(),
                categorias
            );
        }).collect(Collectors.toList());
    }
    
    // ===== MÉTODOS AUXILIARES =====
    
    private MarcaResponseDTO mapToResponseDTO(Marca marca) {
        MarcaResponseDTO dto = new MarcaResponseDTO();
        dto.setIdMarca(marca.getIdMarca());
        dto.setNomeMarca(marca.getNomeMarca());
        return dto;
    }
}