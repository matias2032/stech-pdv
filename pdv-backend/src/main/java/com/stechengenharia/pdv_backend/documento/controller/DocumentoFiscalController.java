

package com.stechengenharia.pdv_backend.documento.controller;


import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.AnularDocumentoRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.EmitirDocumentoMultiplosRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.EmitirDocumentoRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.EmitirNotaRetificativaRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalResponse.DocumentoResponse;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalResponse.NotaRetificativaResponse;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalResponse.TipoDocumentoResponse;
import com.stechengenharia.pdv_backend.documento.dto.ExtractoDocumentalClienteResponseDTO;
import com.stechengenharia.pdv_backend.documento.service.DocumentoFiscalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/documentos-fiscais")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")   // ajustar para o domínio do cliente em produção
public class DocumentoFiscalController {

    private final DocumentoFiscalService service;

    // ── Tipos de documento ────────────────────────────────────────────────

    /** Lista todos os tipos de documento fiscal (FAT, COT, REC, NCO…). */
    @GetMapping("/tipos")
    public ResponseEntity<List<TipoDocumentoResponse>> listarTipos() {
        return ResponseEntity.ok(service.listarTipos());
    }

    /** Devolve um tipo de documento pelo seu id. */
    @GetMapping("/tipos/{id}")
    public ResponseEntity<TipoDocumentoResponse> buscarTipoPorId(
            @PathVariable Integer id) {
        return ResponseEntity.ok(service.buscarTipoPorId(id));
    }

    // ── Documentos fiscais ────────────────────────────────────────────────

    /** Lista todos os documentos fiscais (activos e anulados). */
    @GetMapping
    public ResponseEntity<List<DocumentoResponse>> listarTodos() {
        return ResponseEntity.ok(service.listarTodos());
    }

    /** Devolve um documento pelo seu id. */
    @GetMapping("/{id}")
    public ResponseEntity<DocumentoResponse> buscarPorId(
            @PathVariable Integer id) {
        return ResponseEntity.ok(service.buscarPorId(id));
    }

    /**
     * Devolve um documento pela referência (ex: FAT-0001/2026).
     * encode=false permite o '/' na referência sem double-encoding.
     */
    @GetMapping("/referencia/{referencia:.+}")
    public ResponseEntity<DocumentoResponse> buscarPorReferencia(
            @PathVariable String referencia) {
        return ResponseEntity.ok(service.buscarPorReferencia(referencia));
    }

    /** Lista todos os documentos de um pedido específico. */
    @GetMapping("/pedido/{idPedido}")
    public ResponseEntity<List<DocumentoResponse>> listarPorPedido(
            @PathVariable Integer idPedido) {
        return ResponseEntity.ok(service.listarPorPedido(idPedido));
    }

    /** Lista todos os documentos de um tipo específico. */
    @GetMapping("/tipo/{idTipoDoc}")
    public ResponseEntity<List<DocumentoResponse>> listarPorTipo(
            @PathVariable Integer idTipoDoc) {
        return ResponseEntity.ok(service.listarPorTipo(idTipoDoc));
    }

    /**
     * Emite um novo documento fiscal invocando a função PL/pgSQL
     * emitir_documento_fiscal(). Devolve 201 Created com o documento emitido.
     */
    @PostMapping("/emitir")
    public ResponseEntity<DocumentoResponse> emitir(
            @Valid @RequestBody EmitirDocumentoRequest request) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(service.emitir(request));
    }

    /**
     * Anula um documento já emitido. Operação irreversível — apenas marca
     * anulado=true e regista o motivo. Devolve o documento actualizado.
     */
    @PatchMapping("/{id}/anular")
    public ResponseEntity<DocumentoResponse> anular(
            @PathVariable Integer id,
            @Valid @RequestBody AnularDocumentoRequest request) {
        return ResponseEntity.ok(service.anular(id, request));
    }

    /**
     * Elimina fisicamente um documento. Usar apenas em ambiente de
     * desenvolvimento / testes. Em produção prefira a anulação.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Integer id) {
        service.eliminar(id);
        return ResponseEntity.noContent().build();
    }


    @PostMapping("/emitir-multiplos")
public ResponseEntity<DocumentoResponse> emitirMultiplos(
        @Valid @RequestBody EmitirDocumentoMultiplosRequest request) {
    return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(service.emitirMultiplos(request));
}

/**
 * GET /api/documentos-fiscais/clientes/{idCliente}/extracto
 * Extracto documental do cliente: facturas e VDs emitidos.
 */
@GetMapping("/clientes/{idCliente}/extracto")
public ResponseEntity<ExtractoDocumentalClienteResponseDTO> extractoDocumentalCliente(
        @PathVariable Long idCliente) {
    return ResponseEntity.ok(service.extractoDocumentalCliente(idCliente));
}

/**
 * POST /api/documentos-fiscais/{id}/nota-retificativa
 * Emite uma Nota de Crédito (NCR) ou Nota de Débito (NDB) ligada ao documento {id}.
 */
@PostMapping("/{id}/nota-retificativa")
public ResponseEntity<NotaRetificativaResponse> emitirNotaRetificativa(
        @PathVariable Integer id,
        @Valid @RequestBody EmitirNotaRetificativaRequest request) {
    return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(service.emitirNotaRetificativa(id, request));
}
}
