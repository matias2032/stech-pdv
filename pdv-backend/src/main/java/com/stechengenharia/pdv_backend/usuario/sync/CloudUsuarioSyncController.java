package com.stechengenharia.pdv_backend.usuario.sync;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/sync/usuarios")
@RequiredArgsConstructor
public class CloudUsuarioSyncController {

    private final CloudUsuarioSyncService cloudSyncService;

    @Value("${sync.api-key}")
    private String syncApiKey;

    // ── PUSH: recebe dados da loja ────────────────────────────────────

    @PostMapping
    public ResponseEntity<Void> receberPush(
            @RequestHeader("X-Sync-Api-Key") String key,
            @RequestBody List<UsuarioSyncDTO> payload) {

        if (!syncApiKey.equals(key)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        try {
            cloudSyncService.processarPush(payload);
            log.info("[CloudSync] PUSH recebido: {} usuários de loja", payload.size());
            return ResponseEntity.ok().build();

        } catch (Exception e) {
            // Retorna 500 → o cliente local mantém PENDING e tenta de novo
            log.error("[CloudSync] Erro ao processar PUSH: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // ── PULL: responde com dados atualizados desde 'since' ────────────

    @GetMapping
    public ResponseEntity<List<UsuarioSyncDTO>> responderPull(
            @RequestHeader("X-Sync-Api-Key") String key,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
            OffsetDateTime since) {

        if (!syncApiKey.equals(key)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        List<UsuarioSyncDTO> atualizados = cloudSyncService.buscarAtualizadosDesde(since);
        log.info("[CloudSync] PULL respondido: {} registos desde {}", atualizados.size(), since);
        return ResponseEntity.ok(atualizados);
    }
}