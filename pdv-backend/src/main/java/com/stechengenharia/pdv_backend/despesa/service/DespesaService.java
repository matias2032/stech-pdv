package com.stechengenharia.pdv_backend.despesa.service;

import com.stechengenharia.pdv_backend.despesa.dto.DespesaRequestDTO;
import com.stechengenharia.pdv_backend.despesa.dto.DespesaResponseDTO;
import com.stechengenharia.pdv_backend.despesa.entity.Despesa;
import com.stechengenharia.pdv_backend.despesa.exception.DespesaNotFoundException;
import com.stechengenharia.pdv_backend.despesa.repository.DespesaRepository;
import com.stechengenharia.pdv_backend.fornecedor.entity.Fornecedor;
import com.stechengenharia.pdv_backend.fornecedor.repository.FornecedorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DespesaService {

    private final DespesaRepository despesaRepository;
    private final FornecedorRepository fornecedorRepository;

    // ─── LISTAR TODAS ───────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<DespesaResponseDTO> listarTodas() {
        return despesaRepository.findByDeletedFalseOrderByDataDespesaDesc()
                .stream()
                .map(DespesaResponseDTO::from)
                .toList();
    }

    // ─── BUSCAR POR ID ──────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public DespesaResponseDTO buscarPorId(Long id) {
        Despesa despesa = buscarEntidadePorId(id);
        return DespesaResponseDTO.from(despesa);
    }

    // ─── LISTAR POR FORNECEDOR ──────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<DespesaResponseDTO> listarPorFornecedor(Long idFornecedor) {
        return despesaRepository
.findByFornecedor_IdAndDeletedFalseOrderByDataDespesaDesc(idFornecedor)
                .stream()
                .map(DespesaResponseDTO::from)
                .toList();
    }

    // ─── LISTAR POR PERÍODO ─────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<DespesaResponseDTO> listarPorPeriodo(
            OffsetDateTime inicio,
            OffsetDateTime fim
    ) {
        return despesaRepository
                .findByDataDespesaBetweenAndDeletedFalseOrderByDataDespesaDesc(inicio, fim)
                .stream()
                .map(DespesaResponseDTO::from)
                .toList();
    }

    // ─── CRIAR ──────────────────────────────────────────────────────────────

    @Transactional
    public DespesaResponseDTO criar(DespesaRequestDTO dto) {
        Fornecedor fornecedor = resolverFornecedor(dto.idFornecedor());

        Despesa despesa = Despesa.builder()
                .fornecedor(fornecedor)
                .descricao(dto.descricao())
                .valorGasto(dto.valorGasto())
                .dataDespesa(OffsetDateTime.now())
                .build();

        despesa.setSyncStatus("PENDING_CREATE");

        Despesa salva = despesaRepository.save(despesa);

        return DespesaResponseDTO.from(salva);
    }

    // ─── EDITAR ─────────────────────────────────────────────────────────────

    @Transactional
    public DespesaResponseDTO editar(Long id, DespesaRequestDTO dto) {
        Despesa despesa = buscarEntidadePorId(id);

        Fornecedor fornecedor = resolverFornecedor(dto.idFornecedor());

        despesa.setFornecedor(fornecedor);
        despesa.setDescricao(dto.descricao());
        despesa.setValorGasto(dto.valorGasto());

        marcarComoPendenteUpdate(despesa);

        Despesa atualizada = despesaRepository.save(despesa);

        return DespesaResponseDTO.from(atualizada);
    }

    // ─── EXCLUIR / SOFT DELETE ──────────────────────────────────────────────

    @Transactional
    public void excluir(Long id) {
        Despesa despesa = buscarEntidadePorId(id);

        despesa.setDeleted(true);
        despesa.setSyncStatus("PENDING_DELETE");

        despesaRepository.save(despesa);
    }

    // ─── HELPERS ────────────────────────────────────────────────────────────

    private Despesa buscarEntidadePorId(Long id) {
        return despesaRepository.findById(id)
                .filter(d -> !d.isDeleted())
                .orElseThrow(() -> new DespesaNotFoundException(id));
    }

private Fornecedor resolverFornecedor(Long idFornecedor) {
    if (idFornecedor == null) {
        return null;
    }

    return fornecedorRepository.findByIdAtivo(idFornecedor)
            .orElseThrow(() -> new RuntimeException(
                    "Fornecedor não encontrado com id: " + idFornecedor
            ));
}

    private void marcarComoPendenteUpdate(Despesa despesa) {
        if (!"PENDING_CREATE".equalsIgnoreCase(despesa.getSyncStatus())) {
            despesa.setSyncStatus("PENDING_UPDATE");
        }
    }
}