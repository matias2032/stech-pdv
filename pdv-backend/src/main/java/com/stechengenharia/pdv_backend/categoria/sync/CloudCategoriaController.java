package com.stechengenharia.pdv_backend.categoria.sync;


import com.stechengenharia.pdv_backend.categoria.sync.CategoriaSyncCloudService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/sync/categorias")
@RequiredArgsConstructor
public class CloudCategoriaController {

    private final CategoriaSyncCloudService service;

    /**
     * PUSH: recebe lote da loja local.
     * A chave de API é validada por um filtro/interceptor central — não repete aqui.
     */
    @PostMapping
    public ResponseEntity<Void> receber(@RequestBody List<CategoriaSyncDTO> dtos) {
        service.aplicarLote(dtos);
        return ResponseEntity.ok().build();
    }

    /**
     * PULL: devolve tudo actualizado após 'since'.
     */
    @GetMapping
    public ResponseEntity<List<CategoriaSyncDTO>> listar(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarDesde(since));
    }
}