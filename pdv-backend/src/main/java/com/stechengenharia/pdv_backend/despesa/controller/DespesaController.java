package com.stechengenharia.pdv_backend.despesa.controller;

import com.stechengenharia.pdv_backend.despesa.dto.DespesaRequestDTO;
import com.stechengenharia.pdv_backend.despesa.dto.DespesaResponseDTO;
import com.stechengenharia.pdv_backend.despesa.service.DespesaService;
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

    @GetMapping
    public ResponseEntity<List<DespesaResponseDTO>> listarTodas() {
        return ResponseEntity.ok(despesaService.listarTodas());
    }

    @GetMapping("/{id}")
    public ResponseEntity<DespesaResponseDTO> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(despesaService.buscarPorId(id));
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
}