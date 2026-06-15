package com.stechengenharia.pdv_backend.cotacao.controller;

import com.stechengenharia.pdv_backend.cotacao.dto.CotacaoRequestDTO;
import com.stechengenharia.pdv_backend.cotacao.dto.CotacaoResponseDTO;
import com.stechengenharia.pdv_backend.cotacao.service.CotacaoService;
import com.stechengenharia.pdv_backend.pedido.dto.PedidoResponseDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class CotacaoController {

    private final CotacaoService cotacaoService;

    // ════════════════════════════════════════════════════════════════════
    // COTAÇÃO — CRUD base
    // ════════════════════════════════════════════════════════════════════

    // ── POST /api/cotacoes ────────────────────────────────────────────
    @PostMapping("/api/cotacoes")
    public ResponseEntity<CotacaoResponseDTO.Detalhe> criar(
            @Valid @RequestBody CotacaoRequestDTO.Criar dto) {

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(cotacaoService.criarCotacao(dto));
    }

    // ── GET /api/cotacoes ─────────────────────────────────────────────
    // ?status=ABERTA   → filtra por status
    // ?idCliente=1     → filtra por cliente
    // ?idUsuario=2     → filtra por utilizador
    // (sem params)     → lista todas
    @GetMapping("/api/cotacoes")
    public ResponseEntity<List<CotacaoResponseDTO.Detalhe>> listar(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Long idCliente,
            @RequestParam(required = false) Long idUsuario) {

        if (status != null && !status.isBlank()) {
            return ResponseEntity.ok(cotacaoService.listarPorStatus(status));
        }
        if (idCliente != null) {
            return ResponseEntity.ok(cotacaoService.listarPorCliente(idCliente));
        }
        if (idUsuario != null) {
            return ResponseEntity.ok(cotacaoService.listarPorUsuario(idUsuario));
        }
        return ResponseEntity.ok(cotacaoService.listarTodas());
    }

    // ── GET /api/cotacoes/{idCotacao} ─────────────────────────────────
    @GetMapping("/api/cotacoes/{idCotacao}")
    public ResponseEntity<CotacaoResponseDTO.Detalhe> buscarPorId(
            @PathVariable Long idCotacao) {

        return ResponseEntity.ok(cotacaoService.buscarPorId(idCotacao));
    }

    // ── PUT /api/cotacoes/{idCotacao} ─────────────────────────────────
    @PutMapping("/api/cotacoes/{idCotacao}")
    public ResponseEntity<CotacaoResponseDTO.Detalhe> atualizar(
            @PathVariable Long idCotacao,
            @Valid @RequestBody CotacaoRequestDTO  .Atualizar dto) {

        return ResponseEntity.ok(cotacaoService.atualizarCotacao(idCotacao, dto));
    }

    // ── DELETE /api/cotacoes/{idCotacao} ──────────────────────────────
    @DeleteMapping("/api/cotacoes/{idCotacao}")
    public ResponseEntity<Void> excluir(
            @PathVariable Long idCotacao) {

        cotacaoService.excluirCotacao(idCotacao);
        return ResponseEntity.noContent().build(); // 204
            }

            @GetMapping("/api/cotacoes/prontas")
public ResponseEntity<List<CotacaoResponseDTO.Detalhe>> listarProntas() {
    return ResponseEntity.ok(cotacaoService.listarProntas());
}

    // ════════════════════════════════════════════════════════════════════
    // ITENS DE PRODUTO
    // ════════════════════════════════════════════════════════════════════

    // ── POST /api/cotacoes/{idCotacao}/produtos ───────────────────────
    @PostMapping("/api/cotacoes/{idCotacao}/produtos")
    public ResponseEntity<CotacaoResponseDTO.Detalhe> adicionarProduto(
            @PathVariable Long idCotacao,
            @Valid @RequestBody CotacaoRequestDTO.AdicionarProduto dto) {

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(cotacaoService.adicionarProduto(idCotacao, dto));
    }

    // ── PUT /api/cotacoes/{idCotacao}/produtos/{idItem} ───────────────
    @PutMapping("/api/cotacoes/{idCotacao}/produtos/{idItem}")
    public ResponseEntity<CotacaoResponseDTO    .Detalhe> atualizarItemProduto(
            @PathVariable Long idCotacao,
            @PathVariable Long idItem,
            @Valid @RequestBody CotacaoRequestDTO.AtualizarItem dto) {

        return ResponseEntity.ok(
                cotacaoService.atualizarItemProduto(idCotacao, idItem, dto));
    }

    // ── DELETE /api/cotacoes/{idCotacao}/produtos/{idItem} ────────────
    @DeleteMapping("/api/cotacoes/{idCotacao}/produtos/{idItem}")
    public ResponseEntity<Void> removerItemProduto(
            @PathVariable Long idCotacao,
            @PathVariable Long idItem) {

        cotacaoService.removerItemProduto(idCotacao, idItem);
        return ResponseEntity.noContent().build(); // 204
    }

    // ════════════════════════════════════════════════════════════════════
    // ITENS DE SERVIÇO
    // ════════════════════════════════════════════════════════════════════

    // ── POST /api/cotacoes/{idCotacao}/servicos ───────────────────────
    @PostMapping("/api/cotacoes/{idCotacao}/servicos")
    public ResponseEntity<CotacaoResponseDTO.Detalhe> adicionarServico(
            @PathVariable Long idCotacao,
            @Valid @RequestBody CotacaoRequestDTO.AdicionarServico dto) {

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(cotacaoService.adicionarServico(idCotacao, dto));
    }

    // ── PUT /api/cotacoes/{idCotacao}/servicos/{idItem} ───────────────
    @PutMapping("/api/cotacoes/{idCotacao}/servicos/{idItem}")
    public ResponseEntity<CotacaoResponseDTO.Detalhe> atualizarItemServico(
            @PathVariable Long idCotacao,
            @PathVariable Long idItem,
            @Valid @RequestBody CotacaoRequestDTO.AtualizarItem dto) {

        return ResponseEntity.ok(
                cotacaoService.atualizarItemServico(idCotacao, idItem, dto));
    }

    // ── DELETE /api/cotacoes/{idCotacao}/servicos/{idItem} ────────────
    @DeleteMapping("/api/cotacoes/{idCotacao}/servicos/{idItem}")
    public ResponseEntity<Void> removerItemServico(
            @PathVariable Long idCotacao,
            @PathVariable Long idItem) {

        cotacaoService.removerItemServico(idCotacao, idItem);
        return ResponseEntity.noContent().build(); // 204
    }

    // ════════════════════════════════════════════════════════════════════
    // CONVERSÃO
    // ════════════════════════════════════════════════════════════════════

    // ── POST /api/cotacoes/{idCotacao}/converter-em-pedido ────────────
    @PostMapping("/api/cotacoes/{idCotacao}/converter-em-pedido")
    public ResponseEntity<PedidoResponseDTO> converterEmPedido(
            @PathVariable Long idCotacao,
            @Valid @RequestBody CotacaoRequestDTO.ConverterEmPedido dto) {

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(cotacaoService.converterEmPedido(idCotacao, dto));
    }
}