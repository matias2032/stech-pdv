package com.stechengenharia.pdv_backend.pedido.controller;

import com.stechengenharia.pdv_backend.pedido.dto.*;
import com.stechengenharia.pdv_backend.pedido.service.PedidoService;
import com.stechengenharia.pdv_backend.pedido.repository.PedidoRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/pedidos")
@RequiredArgsConstructor
public class PedidoController {

    private final PedidoService     pedidoService;
    private final PedidoRepository  pedidoRepository;

    // ─── a) Criar pedido ─────────────────────────────────────────────────────

    /**
     * POST /api/pedidos
     * Cria um pedido com itens de produto e/ou serviço.
     * Status inicial: "aberto". Desconta estoque imediatamente.
     */
    @PostMapping
    public ResponseEntity<PedidoResponseDTO> criarPedido(
            @Valid @RequestBody PedidoRequestDTO dto) {

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(pedidoService.criarPedido(dto));
    }

    // ─── b) Adicionar item de produto ────────────────────────────────────────

    /**
     * POST /api/pedidos/{idPedido}/itens/produto
     */
    @PostMapping("/{idPedido}/itens/produto")
    public ResponseEntity<PedidoResponseDTO> adicionarItemProduto(
            @PathVariable Integer idPedido,
            @Valid @RequestBody ItemPedidoRequestDTO dto) {

        return ResponseEntity.ok(pedidoService.adicionarItemProduto(idPedido, dto));
    }

    // ─── c) Adicionar item de serviço ────────────────────────────────────────

    /**
     * POST /api/pedidos/{idPedido}/itens/servico
     */
    @PostMapping("/{idPedido}/itens/servico")
    public ResponseEntity<PedidoResponseDTO> adicionarItemServico(
            @PathVariable Integer idPedido,
            @Valid @RequestBody ItemServicoRequestDTO dto) {

        return ResponseEntity.ok(pedidoService.adicionarItemServico(idPedido, dto));
    }

    // ─── d) Editar quantidade de item de produto ─────────────────────────────

    /**
     * PATCH /api/pedidos/{idPedido}/itens/produto/{idItemPedido}
     */
    @PatchMapping("/{idPedido}/itens/produto/{idItemPedido}")
    public ResponseEntity<PedidoResponseDTO> editarQuantidadeItemProduto(
            @PathVariable Integer idPedido,
            @PathVariable Integer idItemPedido,
            @Valid @RequestBody EditarItemRequestDTO dto) {

        return ResponseEntity.ok(
                pedidoService.editarQuantidadeItemProduto(idPedido, idItemPedido, dto));
    }

    // ─── e) Editar quantidade de item de serviço ─────────────────────────────

    /**
     * PATCH /api/pedidos/{idPedido}/itens/servico/{idItemServico}
     */
    @PatchMapping("/{idPedido}/itens/servico/{idItemServico}")
    public ResponseEntity<PedidoResponseDTO> editarQuantidadeItemServico(
            @PathVariable Integer idPedido,
            @PathVariable Integer idItemServico,
            @Valid @RequestBody EditarItemRequestDTO dto) {

        return ResponseEntity.ok(
                pedidoService.editarQuantidadeItemServico(idPedido, idItemServico, dto));
    }

    // ─── f) Eliminar item de produto ─────────────────────────────────────────

    /**
     * DELETE /api/pedidos/{idPedido}/itens/produto/{idItemPedido}
     */
    @DeleteMapping("/{idPedido}/itens/produto/{idItemPedido}")
    public ResponseEntity<PedidoResponseDTO> eliminarItemProduto(
            @PathVariable Integer idPedido,
            @PathVariable Integer idItemPedido) {

        return ResponseEntity.ok(pedidoService.eliminarItemProduto(idPedido, idItemPedido));
    }

    // ─── g) Eliminar item de serviço ─────────────────────────────────────────

    /**
     * DELETE /api/pedidos/{idPedido}/itens/servico/{idItemServico}
     */
    @DeleteMapping("/{idPedido}/itens/servico/{idItemServico}")
    public ResponseEntity<PedidoResponseDTO> eliminarItemServico(
            @PathVariable Integer idPedido,
            @PathVariable Integer idItemServico) {

        return ResponseEntity.ok(pedidoService.eliminarItemServico(idPedido, idItemServico));
    }

    // ─── h) Finalizar pedido ─────────────────────────────────────────────────

    /**
     * POST /api/pedidos/{idPedido}/finalizar
     * Regista o valor pago; troco calculado pela BD automaticamente.
     */
    @PostMapping("/{idPedido}/finalizar")
    public ResponseEntity<PedidoResponseDTO> finalizarPedido(
            @PathVariable Integer idPedido,
            @RequestBody FinalizarPedidoRequestDTO dto) {

        return ResponseEntity.ok(pedidoService.finalizarPedido(idPedido, dto));
    }

    // ─── i) Cancelar pedido ──────────────────────────────────────────────────

    /**
     * POST /api/pedidos/{idPedido}/cancelar
     * Cancela o pedido e restaura estoque dos itens de produto.
     */
    @PostMapping("/{idPedido}/cancelar")
    public ResponseEntity<Void> cancelarPedido(
            @PathVariable Integer idPedido,
            @Valid @RequestBody CancelamentoPedidoRequestDTO dto) {

        pedidoService.cancelarPedido(idPedido, dto);
        return ResponseEntity.noContent().build();
    }

    // ─── Consultas simples ────────────────────────────────────────────────────

    /** GET /api/pedidos/{idPedido} */
    @GetMapping("/{idPedido}")
    public ResponseEntity<PedidoResponseDTO> buscarPorId(
            @PathVariable Integer idPedido) {

        return ResponseEntity.ok(pedidoService.buscarPorId(idPedido));
    }

    /** GET /api/pedidos/usuario/{idUsuario} */
    @GetMapping("/usuario/{idUsuario}")
    public ResponseEntity<List<PedidoResponseDTO>> listarPorUsuario(
            @PathVariable Integer idUsuario) {

        return ResponseEntity.ok(pedidoService.listarPorUsuario(idUsuario));
    }

    /** GET /api/pedidos/status/{status} */
    @GetMapping("/status/{status}")
    public ResponseEntity<List<PedidoResponseDTO>> listarPorStatus(
            @PathVariable String status) {

        return ResponseEntity.ok(pedidoService.listarPorStatus(status));
    }

    /** GET /api/pedidos/usuario/{idUsuario}/status/{status} */
    @GetMapping("/usuario/{idUsuario}/status/{status}")
    public ResponseEntity<List<PedidoResponseDTO>> listarPorUsuarioEStatus(
            @PathVariable Integer idUsuario,
            @PathVariable String status) {

        return ResponseEntity.ok(pedidoService.listarPorUsuarioEStatus(idUsuario, status));
    }

    /** GET /api/pedidos/tipos-pagamento */
    @GetMapping("/tipos-pagamento")
    public ResponseEntity<List<TipoPagamentoResponseDTO>> listarTiposPagamento() {
        return ResponseEntity.ok(pedidoService.listarTiposPagamento());
    }

    // ─── Relatórios / Dashboard ───────────────────────────────────────────────

    /**
     * GET /api/pedidos/usuario/{idUsuario}/relatorio?dataInicio=2026-01-01T00:00:00
     */
    @GetMapping("/usuario/{idUsuario}/relatorio")
    public ResponseEntity<Map<String, Object>> relatorioPedidosUsuario(
            @PathVariable Integer idUsuario,
            @RequestParam String dataInicio) {

        LocalDateTime inicio = LocalDateTime.parse(dataInicio, DateTimeFormatter.ISO_DATE_TIME);

        List<Object[]> evolucao = pedidoRepository.evolucaoPedidosPorUsuario(idUsuario, inicio);
        long total = pedidoRepository.totalPedidosPorUsuario(idUsuario, inicio);

        List<Map<String, Object>> porDia = evolucao.stream().map(row -> {
            Map<String, Object> item = new java.util.HashMap<>();
            item.put("data",          row[0].toString());
            item.put("total_pedidos", ((Number) row[1]).longValue());
            return item;
        }).collect(Collectors.toList());

        Map<String, Object> resultado = new java.util.HashMap<>();
        resultado.put("totalPedidos", total);
        resultado.put("porDia",       porDia);

        return ResponseEntity.ok(resultado);
    }

    /**
     * GET /api/pedidos/usuario/{idUsuario}/dashboard?dataInicio=2026-01-01T00:00:00
     */
    @GetMapping("/usuario/{idUsuario}/dashboard")
    public ResponseEntity<Map<String, Object>> dashboardUsuario(
            @PathVariable Integer idUsuario,
            @RequestParam String dataInicio) {

        LocalDateTime inicio = LocalDateTime.parse(dataInicio, DateTimeFormatter.ISO_DATE_TIME);

        List<Object[]> evolucao = pedidoRepository.evolucaoVendasPorUsuario(idUsuario, inicio);
        List<Map<String, Object>> porDia = evolucao.stream().map(row -> {
            Map<String, Object> item = new java.util.HashMap<>();
            item.put("data",         row[0].toString());
            item.put("total_vendas", ((Number) row[1]).doubleValue());
            return item;
        }).collect(Collectors.toList());

        long totalPedidos             = pedidoRepository.totalPedidosPorUsuario(idUsuario, inicio);
        java.math.BigDecimal totalVendas = pedidoRepository.totalVendasPorUsuario(idUsuario, inicio);

        Map<String, Object> resultado = new java.util.HashMap<>();
        resultado.put("totalPedidos", totalPedidos);
        resultado.put("totalVendas",  totalVendas);
        resultado.put("porDia",       porDia);

        return ResponseEntity.ok(resultado);
    }

    /** GET /api/pedidos/count/abertos */
@GetMapping("/count/abertos")
public ResponseEntity<Map<String, Long>> contarPedidosAbertos() {
    Map<String, Long> resp = new java.util.HashMap<>();
    resp.put("total", pedidoRepository.contarPedidosAbertos());
    return ResponseEntity.ok(resp);
}
}