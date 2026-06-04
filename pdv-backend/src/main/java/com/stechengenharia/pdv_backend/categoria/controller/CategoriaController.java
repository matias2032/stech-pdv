package com.stechengenharia.pdv_backend.categoria.controller;

import com.stechengenharia.pdv_backend.categoria.dto.CategoriaRequestDTO;
import com.stechengenharia.pdv_backend.categoria.dto.CategoriaResponseDTO;
import com.stechengenharia.pdv_backend.categoria.service.CategoriaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categorias")
@RequiredArgsConstructor
@Slf4j
public class CategoriaController {
    
    private final CategoriaService categoriaService;
    
    // ===== CRUD BÁSICO =====
    
    @PostMapping
    public ResponseEntity<CategoriaResponseDTO> criar(@Valid @RequestBody CategoriaRequestDTO dto) {
        log.info("POST /api/categorias - Criar categoria: {}", dto.getNomeCategoria());
        CategoriaResponseDTO response = categoriaService.criar(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping
    public ResponseEntity<List<CategoriaResponseDTO>> listar() {
        log.info("GET /api/categorias - Listar todas as categorias");
        List<CategoriaResponseDTO> categorias = categoriaService.listar();
        return ResponseEntity.ok(categorias);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<CategoriaResponseDTO> buscarPorId(@PathVariable Integer id) {
        log.info("GET /api/categorias/{} - Buscar categoria por ID", id);
        CategoriaResponseDTO categoria = categoriaService.buscarPorId(id);
        return ResponseEntity.ok(categoria);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<CategoriaResponseDTO> atualizar(
            @PathVariable Integer id, 
            @Valid @RequestBody CategoriaRequestDTO dto) {
        log.info("PUT /api/categorias/{} - Atualizar categoria", id);
        CategoriaResponseDTO response = categoriaService.atualizar(id, dto);
        return ResponseEntity.ok(response);
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Integer id) {
        log.info("DELETE /api/categorias/{} - Deletar categoria", id);
        categoriaService.deletar(id);
        return ResponseEntity.noContent().build();
    }
    
    // ===== ASSOCIAÇÕES COM PRODUTOS =====
    
    @PostMapping("/{idCategoria}/produtos/{idProduto}")
    public ResponseEntity<Void> associarProduto(
            @PathVariable Integer idCategoria, 
            @PathVariable Integer idProduto) {
        log.info("POST /api/categorias/{}/produtos/{} - Associar produto", idCategoria, idProduto);
        categoriaService.associarProduto(idCategoria, idProduto);
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{idCategoria}/produtos/{idProduto}")
    public ResponseEntity<Void> desassociarProduto(
            @PathVariable Integer idCategoria, 
            @PathVariable Integer idProduto) {
        log.info("DELETE /api/categorias/{}/produtos/{} - Desassociar produto", idCategoria, idProduto);
        categoriaService.desassociarProduto(idCategoria, idProduto);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{idCategoria}/produtos")
    public ResponseEntity<List<Integer>> listarProdutos(@PathVariable Integer idCategoria) {
        log.info("GET /api/categorias/{}/produtos - Listar produtos da categoria", idCategoria);
        List<Integer> produtos = categoriaService.listarProdutosDaCategoria(idCategoria);
        return ResponseEntity.ok(produtos);
    }
    
    // ===== ASSOCIAÇÕES COM MARCAS =====
    
    @PostMapping("/{idCategoria}/marcas/{idMarca}")
    public ResponseEntity<Void> associarMarca(
            @PathVariable Integer idCategoria, 
            @PathVariable Integer idMarca) {
        log.info("POST /api/categorias/{}/marcas/{} - Associar marca", idCategoria, idMarca);
        categoriaService.associarMarca(idCategoria, idMarca);
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{idCategoria}/marcas/{idMarca}")
    public ResponseEntity<Void> desassociarMarca(
            @PathVariable Integer idCategoria, 
            @PathVariable Integer idMarca) {
        log.info("DELETE /api/categorias/{}/marcas/{} - Desassociar marca", idCategoria, idMarca);
        categoriaService.desassociarMarca(idCategoria, idMarca);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{idCategoria}/marcas")
    public ResponseEntity<List<Integer>> listarMarcas(@PathVariable Integer idCategoria) {
        log.info("GET /api/categorias/{}/marcas - Listar marcas da categoria", idCategoria);
        List<Integer> marcas = categoriaService.listarMarcasDaCategoria(idCategoria);
        return ResponseEntity.ok(marcas);
    }
}