package com.stechengenharia.pdv_backend.marca.controller;

import com.stechengenharia.pdv_backend.marca.dto.MarcaComCategoriasDTO;
import com.stechengenharia.pdv_backend.marca.dto.MarcaRequestDTO;
import com.stechengenharia.pdv_backend.marca.dto.MarcaResponseDTO;
import com.stechengenharia.pdv_backend.marca.service.MarcaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/marcas")
@RequiredArgsConstructor
@Slf4j
public class MarcaController {
    
    private final MarcaService marcaService;
    
    @PostMapping
    public ResponseEntity<MarcaResponseDTO> criar(@Valid @RequestBody MarcaRequestDTO dto) {
        log.info("POST /api/marcas - Criar marca: {}", dto.getNomeMarca());
        MarcaResponseDTO response = marcaService.criar(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping
    public ResponseEntity<List<MarcaResponseDTO>> listar() {
        log.info("GET /api/marcas - Listar todas as marcas");
        List<MarcaResponseDTO> marcas = marcaService.listar();
        return ResponseEntity.ok(marcas);
    }
    
    // ===== NOVO ENDPOINT - LISTAR COM CATEGORIAS =====
    @GetMapping("/com-categorias")
    public ResponseEntity<List<MarcaComCategoriasDTO>> listarComCategorias() {
        log.info("GET /api/marcas/com-categorias - Listar marcas com categorias");
        List<MarcaComCategoriasDTO> marcas = marcaService.listarComCategorias();
        return ResponseEntity.ok(marcas);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<MarcaResponseDTO> buscarPorId(@PathVariable Integer id) {
        log.info("GET /api/marcas/{} - Buscar marca por ID", id);
        MarcaResponseDTO marca = marcaService.buscarPorId(id);
        return ResponseEntity.ok(marca);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<MarcaResponseDTO> atualizar(
            @PathVariable Integer id, 
            @Valid @RequestBody MarcaRequestDTO dto) {
        log.info("PUT /api/marcas/{} - Atualizar marca", id);
        MarcaResponseDTO response = marcaService.atualizar(id, dto);
        return ResponseEntity.ok(response);
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Integer id) {
        log.info("DELETE /api/marcas/{} - Deletar marca", id);
        marcaService.deletar(id);
        return ResponseEntity.noContent().build();
    }
}