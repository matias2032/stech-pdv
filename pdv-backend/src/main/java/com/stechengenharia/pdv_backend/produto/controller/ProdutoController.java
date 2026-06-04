package com.stechengenharia.pdv_backend.produto.controller;

import com.stechengenharia.pdv_backend.produto.dto.ProdutoImagemRequestDTO;
import com.stechengenharia.pdv_backend.produto.dto.ProdutoRequestDTO;
import com.stechengenharia.pdv_backend.produto.dto.ProdutoResponseDTO;
import com.stechengenharia.pdv_backend.produto.entity.ProdutoImagem;
import com.stechengenharia.pdv_backend.produto.service.ProdutoService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j; // ✅ ADICIONE este import
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path; // ✅ ADICIONE este import
import java.nio.file.Paths;
import java.util.List;

@RestController
@RequestMapping("/api/produtos")
@RequiredArgsConstructor
@Slf4j // ✅ ADICIONE esta anotação
public class ProdutoController {
    
    private final ProdutoService produtoService;
    private static final Logger log = LoggerFactory.getLogger(ProdutoController.class);
    
    @PostMapping
    public ResponseEntity<ProdutoResponseDTO> criar(@RequestBody ProdutoRequestDTO dto) {
        log.info("🚨 CONTROLLER RECEBEU REQUISIÇÃO POST");
        log.info("🚨 DTO recebido: {}", dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(produtoService.criar(dto));
    }
    
   @PutMapping("/{id}")
public ResponseEntity<ProdutoResponseDTO> atualizar(
        @PathVariable Integer id, 
        @RequestBody ProdutoRequestDTO dto) {
    
    log.info("🚨 CONTROLLER RECEBEU REQUISIÇÃO PUT /{}", id);
    log.info("🚨 DTO recebido: {}", dto);
    log.info("🚨 Categorias no DTO: {}", dto.getCategorias());
    log.info("🚨 Marcas no DTO: {}", dto.getMarcas());
    
    ProdutoResponseDTO response = produtoService.atualizar(id, dto);
    
    log.info("🚨 CONTROLLER RETORNANDO RESPOSTA");
    
    return ResponseEntity.ok(response);
}
    
    @PatchMapping("/{id}/toggle-ativo")
    public ResponseEntity<Void> toggleAtivo(@PathVariable Integer id) {
        produtoService.toggleAtivo(id);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping
    public ResponseEntity<List<ProdutoResponseDTO>> listar() {
        return ResponseEntity.ok(produtoService.listar());
    }
    
    @GetMapping("/ativos")
    public ResponseEntity<List<ProdutoResponseDTO>> listarAtivos() {
        return ResponseEntity.ok(produtoService.listarAtivos());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ProdutoResponseDTO> buscarPorId(@PathVariable Integer id) {
        return ResponseEntity.ok(produtoService.buscarPorId(id));
    }
    
    // ===== CATEGORIAS =====
    
    @PostMapping("/{idProduto}/categorias/{idCategoria}")
    public ResponseEntity<Void> associarCategoria(
            @PathVariable Integer idProduto,
            @PathVariable Integer idCategoria) {
        produtoService.associarCategoria(idProduto, idCategoria);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
    
    @DeleteMapping("/{idProduto}/categorias/{idCategoria}")
    public ResponseEntity<Void> desassociarCategoria(
            @PathVariable Integer idProduto,
            @PathVariable Integer idCategoria) {
        produtoService.desassociarCategoria(idProduto, idCategoria);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{idProduto}/categorias")
    public ResponseEntity<List<Integer>> listarCategorias(@PathVariable Integer idProduto) {
        return ResponseEntity.ok(produtoService.listarCategoriasDoProduto(idProduto));
    }

    // ===== MARCAS =====

    @PostMapping("/{idProduto}/marcas/{idMarca}")
    public ResponseEntity<Void> associarMarca(
            @PathVariable Integer idProduto,
            @PathVariable Integer idMarca) {
        produtoService.associarMarca(idProduto, idMarca);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @DeleteMapping("/{idProduto}/marcas/{idMarca}")
    public ResponseEntity<Void> desassociarMarca(
            @PathVariable Integer idProduto,
            @PathVariable Integer idMarca) {
        produtoService.desassociarMarca(idProduto, idMarca);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{idProduto}/marcas")
    public ResponseEntity<List<Integer>> listarMarcas(@PathVariable Integer idProduto) {
        return ResponseEntity.ok(produtoService.listarMarcasDoProduto(idProduto));
    }

    @GetMapping("/marcas/{idMarca}/produtos")
    public ResponseEntity<List<Integer>> listarProdutosPorMarca(@PathVariable Integer idMarca) {
        return ResponseEntity.ok(produtoService.listarProdutosDaMarca(idMarca));
    }
    
    // ===== IMAGENS =====
    
    // ✅ MANTENHA APENAS ESTE MÉTODO (remova o duplicado)
    @PostMapping("/{idProduto}/imagens")
    public ResponseEntity<Void> adicionarImagem(
            @PathVariable Integer idProduto,
            @RequestParam("imagem") MultipartFile imagem,
            @RequestParam(required = false) String legenda,
            @RequestParam(defaultValue = "0") Short imagemPrincipal) {
        
        log.info("POST /api/produtos/{}/imagens - Adicionar imagem", idProduto);
        
        try {
            // Salvar arquivo no servidor
            String caminhoImagem = salvarArquivo(imagem);
            
            ProdutoImagemRequestDTO dto = new ProdutoImagemRequestDTO();
            dto.setCaminhoImagem(caminhoImagem);
            dto.setLegenda(legenda);
            dto.setImagemPrincipal(imagemPrincipal);
            
            produtoService.adicionarImagem(idProduto, dto);
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (Exception e) {
            log.error("Erro ao adicionar imagem", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @GetMapping("/{idProduto}/imagens")
    public ResponseEntity<List<ProdutoImagem>> listarImagens(@PathVariable Integer idProduto) {
        log.info("GET /api/produtos/{}/imagens - Listar imagens", idProduto);
        List<ProdutoImagem> imagens = produtoService.listarImagensDoProduto(idProduto);
        return ResponseEntity.ok(imagens);
    }
    
    @PatchMapping("/{idProduto}/imagens/{idImagem}/principal")
    public ResponseEntity<Void> definirImagemPrincipal(
            @PathVariable Integer idProduto,
            @PathVariable Integer idImagem) {
        log.info("PATCH /api/produtos/{}/imagens/{}/principal", idProduto, idImagem);
        produtoService.alterarImagemPrincipal(idProduto, idImagem);
        return ResponseEntity.noContent().build();
    }
    
    @DeleteMapping("/imagens/{idImagem}")
    public ResponseEntity<Void> removerImagem(@PathVariable Integer idImagem) {
        log.info("DELETE /api/produtos/imagens/{}", idImagem);
        produtoService.removerImagem(idImagem);
        return ResponseEntity.noContent().build();
    }

    // Método auxiliar para salvar arquivo
private String salvarArquivo(MultipartFile arquivo) throws IOException {
    String nomeOriginal = arquivo.getOriginalFilename();
    if (nomeOriginal == null || nomeOriginal.isBlank()) {
        nomeOriginal = "imagem_" + System.currentTimeMillis();
    }

    // Extrai só o nome do ficheiro, ignorando caminho completo (C:\Users\... ou /home/...)
    nomeOriginal = Paths.get(nomeOriginal).getFileName().toString();

    // Substitui espaços e caracteres especiais por _
    String nomeSanitizado = nomeOriginal.replaceAll("[^a-zA-Z0-9._-]", "_");

    String nomeArquivo = System.currentTimeMillis() + "_" + nomeSanitizado;
    Path path = Paths.get("uploads/produtos/" + nomeArquivo);
    Files.createDirectories(path.getParent());
    Files.write(path, arquivo.getBytes());

    return "/uploads/produtos/" + nomeArquivo;
}
    
}