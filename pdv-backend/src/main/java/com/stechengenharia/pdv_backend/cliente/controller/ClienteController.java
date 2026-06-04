package com.stechengenharia.pdv_backend.cliente.controller;

import com.stechengenharia.pdv_backend.cliente.dto.ClienteRequestDTO;
import com.stechengenharia.pdv_backend.cliente.dto.ClienteResponseDTO;
import com.stechengenharia.pdv_backend.cliente.service.ClienteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ClienteController {

    private final ClienteService clienteService;

    // ── GET /api/clientes ─────────────────────────────────────────────
    // ?perfil=1  → filtra por perfil
    // ?q=texto   → pesquisa por nome/email/contacto/nuit
    // (sem params) → lista todos

    @GetMapping("/api/clientes")
    public ResponseEntity<List<ClienteResponseDTO>> listar(
            @RequestParam(required = false) Long perfil,
            @RequestParam(required = false) String q) {

        if (q != null && !q.isBlank()) {
            return ResponseEntity.ok(clienteService.pesquisar(q));
        }
        if (perfil != null) {
            return ResponseEntity.ok(clienteService.listarPorPerfil(perfil));
        }
        return ResponseEntity.ok(clienteService.listarTodos());
    }

    // ── GET /api/clientes/{id} ────────────────────────────────────────

    @GetMapping("/api/clientes/{id}")
    public ResponseEntity<ClienteResponseDTO> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(clienteService.buscarPorId(id));
    }

    // ── POST /api/clientes ────────────────────────────────────────────

    @PostMapping("/api/clientes")
    public ResponseEntity<ClienteResponseDTO> criar(
            @Valid @RequestBody ClienteRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(clienteService.criar(dto));
    }

    // ── PUT /api/clientes/{id} ────────────────────────────────────────

    @PutMapping("/api/clientes/{id}")
    public ResponseEntity<ClienteResponseDTO> editar(
            @PathVariable Long id,
            @Valid @RequestBody ClienteRequestDTO dto) {
        return ResponseEntity.ok(clienteService.editar(id, dto));
    }

    // ── DELETE /api/clientes/{id} ─────────────────────────────────────

    @DeleteMapping("/api/clientes/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        clienteService.excluir(id);
        return ResponseEntity.noContent().build(); // 204
    }
}