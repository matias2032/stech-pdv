package com.stechengenharia.pdv_backend.despesa.controller;

import com.stechengenharia.pdv_backend.despesa.dto.DespesaRequestDTO;
import com.stechengenharia.pdv_backend.despesa.dto.DespesaResponseDTO;
import com.stechengenharia.pdv_backend.despesa.dto.TipoDespesaRequestDTO;
import com.stechengenharia.pdv_backend.despesa.dto.TipoDespesaResponseDTO;
import com.stechengenharia.pdv_backend.despesa.service.DespesaService;
import com.stechengenharia.pdv_backend.despesa.dto.DespesaExclusaoRequestDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/despesas")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DespesaController {

    private final DespesaService despesaService;

    // ══════════════════════════════════════════════════════════════════════
    // TIPOS DE DESPESA
    // IMPORTANTE:
    // Estas rotas ficam antes de "/{id}" para evitar conflito de rota.
    // ══════════════════════════════════════════════════════════════════════

    @GetMapping("/tipos")
    public ResponseEntity<List<TipoDespesaResponseDTO>> listarTiposDespesa() {
        return ResponseEntity.ok(despesaService.listarTiposDespesa());
    }

    @GetMapping("/tipos/{id}")
    public ResponseEntity<TipoDespesaResponseDTO> buscarTipoDespesaPorId(
            @PathVariable Long id
    ) {
        return ResponseEntity.ok(despesaService.buscarTipoDespesaPorId(id));
    }

    @PostMapping("/tipos")
    public ResponseEntity<TipoDespesaResponseDTO> criarTipoDespesa(
            @Valid @RequestBody TipoDespesaRequestDTO dto
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(despesaService.criarTipoDespesa(dto));
    }

    @PutMapping("/tipos/{id}")
    public ResponseEntity<TipoDespesaResponseDTO> editarTipoDespesa(
            @PathVariable Long id,
            @Valid @RequestBody TipoDespesaRequestDTO dto
    ) {
        return ResponseEntity.ok(despesaService.editarTipoDespesa(id, dto));
    }

    @DeleteMapping("/tipos/{id}")
    public ResponseEntity<Void> excluirTipoDespesa(@PathVariable Long id) {
        despesaService.excluirTipoDespesa(id);
        return ResponseEntity.noContent().build();
    }

    // ══════════════════════════════════════════════════════════════════════
    // DESPESAS
    // ══════════════════════════════════════════════════════════════════════

@GetMapping
public ResponseEntity<List<DespesaResponseDTO>> listarTodas() {
    return ResponseEntity.ok(despesaService.listarTodas());
}

@GetMapping("/excluidas")
public ResponseEntity<List<DespesaResponseDTO>> listarExcluidas() {
    return ResponseEntity.ok(despesaService.listarExcluidas());
}

@GetMapping("/fornecedor/{idFornecedor}")
public ResponseEntity<List<DespesaResponseDTO>> listarPorFornecedor(
        @PathVariable Long idFornecedor
) {
    return ResponseEntity.ok(despesaService.listarPorFornecedor(idFornecedor));
}

@GetMapping("/periodo")
public ResponseEntity<List<DespesaResponseDTO>> listarPorPeriodo(
        @RequestParam
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
        OffsetDateTime inicio,

        @RequestParam
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
        OffsetDateTime fim
) {
    return ResponseEntity.ok(despesaService.listarPorPeriodo(inicio, fim));
}

@GetMapping("/{id}")
public ResponseEntity<DespesaResponseDTO> buscarPorId(
        @PathVariable Long id
) {
    return ResponseEntity.ok(despesaService.buscarPorId(id));
}

    @PostMapping
    public ResponseEntity<DespesaResponseDTO> criar(
            @Valid @RequestBody DespesaRequestDTO dto
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(despesaService.criar(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DespesaResponseDTO> editar(
            @PathVariable Long id,
            @Valid @RequestBody DespesaRequestDTO dto
    ) {
        return ResponseEntity.ok(despesaService.editar(id, dto));
    }

@DeleteMapping("/{id}")
public ResponseEntity<Void> excluir(@PathVariable Long id) {
    despesaService.excluir(id);
    return ResponseEntity.noContent().build();
}

@PatchMapping("/{id}/excluir")
public ResponseEntity<Void> excluirComMotivo(
        @PathVariable Long id,
        @Valid @RequestBody DespesaExclusaoRequestDTO dto
) {
    despesaService.excluir(id, dto);
    return ResponseEntity.noContent().build();
}
}



