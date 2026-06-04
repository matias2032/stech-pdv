package com.stechengenharia.pdv_backend.usuario.controller;

import com.stechengenharia.pdv_backend.usuario.dto.AlterarSenhaRequestDTO;
import com.stechengenharia.pdv_backend.usuario.dto.LoginRequestDTO;
import com.stechengenharia.pdv_backend.usuario.dto.TrocarSenhaDTO;
import com.stechengenharia.pdv_backend.usuario.dto.UsuarioRequestDTO;
import com.stechengenharia.pdv_backend.usuario.dto.UsuarioResponseDTO;
import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import com.stechengenharia.pdv_backend.usuario.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    // ── /api/usuarios ─────────────────────────────────────────────────

    @GetMapping("/api/usuarios")
    public ResponseEntity<List<UsuarioResponseDTO>> listar(
            @RequestParam(required = false) Boolean ativo) {
        return ResponseEntity.ok(usuarioService.listarPorStatus(ativo));
    }

    @GetMapping("/api/usuarios/{id}")
    public ResponseEntity<UsuarioResponseDTO> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(usuarioService.buscarPorId(id));
    }

    @PostMapping("/api/usuarios")
    public ResponseEntity<UsuarioResponseDTO> criar(
            @Valid @RequestBody UsuarioRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(usuarioService.salvar(dto));
    }

    @PatchMapping("/api/usuarios/{id}/toggle-ativo")
    public ResponseEntity<UsuarioResponseDTO> toggleAtivo(@PathVariable Long id) {
        return ResponseEntity.ok(usuarioService.toggleAtivo(id));
    }

    @PostMapping("/api/usuarios/{id}/reset-senha")
    public ResponseEntity<Map<String, String>> resetarSenha(@PathVariable Long id) {
        usuarioService.resetarSenha(id);
        return ResponseEntity.ok(
                Map.of("mensagem", "Senha redefinida para o padrão com sucesso."));
    }

    @PostMapping("/api/usuarios/{id}/alterar-senha")
    public ResponseEntity<Void> alterarSenha(
            @PathVariable Long id,
            @RequestBody AlterarSenhaRequestDTO dto) {
        usuarioService.alterarSenha(id, dto.senhaAtual(), dto.novaSenha());
        return ResponseEntity.noContent().build();
    }

    // ── /api/auth ─────────────────────────────────────────────────────

    @PostMapping("/api/auth/login")
    public ResponseEntity<?> login(@RequestBody LoginRequestDTO dto) {
        Usuario usuario = usuarioService.autenticar(dto);

        return ResponseEntity.ok(Map.of(
                "usuario",       new UsuarioResponseDTO(usuario),
                "primeiraSenha", usuario.getPrimeiraSenha()
        ));
    }

    @PatchMapping("/api/auth/{id}/trocar-senha")
    public ResponseEntity<Void> trocarSenha(
            @PathVariable Long id,
            @RequestBody TrocarSenhaDTO dto) {
        usuarioService.trocarPrimeiraSenha(id, dto.novaSenha());
        return ResponseEntity.ok().build();
    }
}