package com.stechengenharia.pdv_backend.sync.controller;

import com.stechengenharia.pdv_backend.sync.dto.SyncRequestDTO;
import com.stechengenharia.pdv_backend.sync.dto.SyncResponseDTO;
import com.stechengenharia.pdv_backend.sync.service.SyncService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/sync")
@RequiredArgsConstructor
public class SyncController {

    private final SyncService syncService;

    /**
     * Recebe um batch de operações offline do Flutter e processa cada uma
     * de forma independente — falha de uma não cancela as restantes.
     *
     * POST /api/sync/batch
     */
    @PostMapping("/batch")
    public ResponseEntity<SyncResponseDTO> batch(@Valid @RequestBody SyncRequestDTO request) {

        log.info("[Sync] Batch recebido: {} operação(ões)", 
                 request.getOperacoes() != null ? request.getOperacoes().size() : 0);

        SyncResponseDTO response = syncService.processar(request);

        log.info("[Sync] Batch concluído: {} sucesso / {} erro",
                 response.getTotalSucesso(), response.getTotalErro());

        return ResponseEntity.ok(response);
    }
}