package com.stechengenharia.pdv_backend.despesa.service;

import com.stechengenharia.pdv_backend.despesa.dto.DespesaRequestDTO;
import com.stechengenharia.pdv_backend.despesa.dto.DespesaResponseDTO;
import com.stechengenharia.pdv_backend.despesa.dto.TipoDespesaRequestDTO;
import com.stechengenharia.pdv_backend.despesa.dto.TipoDespesaResponseDTO;
import com.stechengenharia.pdv_backend.despesa.entity.Despesa;
import com.stechengenharia.pdv_backend.despesa.entity.TipoDespesa;
import com.stechengenharia.pdv_backend.despesa.exception.DespesaNotFoundException;
import com.stechengenharia.pdv_backend.despesa.repository.DespesaRepository;
import com.stechengenharia.pdv_backend.despesa.repository.TipoDespesaRepository;
import com.stechengenharia.pdv_backend.fornecedor.entity.Fornecedor;
import com.stechengenharia.pdv_backend.fornecedor.repository.FornecedorRepository;
import com.stechengenharia.pdv_backend.despesa.dto.DespesaExclusaoRequestDTO;
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
    private final TipoDespesaRepository tipoDespesaRepository;

    // ══════════════════════════════════════════════════════════════════════
    // DESPESAS
    // ══════════════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public List<DespesaResponseDTO> listarTodas() {
        return despesaRepository.findByDeletedFalseOrderByDataDespesaDesc()
                .stream()
                .map(DespesaResponseDTO::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public DespesaResponseDTO buscarPorId(Long id) {
        Despesa despesa = buscarEntidadePorId(id);
        return DespesaResponseDTO.from(despesa);
    }

    @Transactional(readOnly = true)
    public List<DespesaResponseDTO> listarPorFornecedor(Long idFornecedor) {
        return despesaRepository
                .findByFornecedor_IdAndDeletedFalseOrderByDataDespesaDesc(idFornecedor)
                .stream()
                .map(DespesaResponseDTO::from)
                .toList();
    }

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

    @Transactional
    public DespesaResponseDTO criar(DespesaRequestDTO dto) {
        Fornecedor fornecedor = resolverFornecedor(dto.idFornecedor());
        TipoDespesa tipoDespesa = resolverTipoDespesa(dto.idTipoDespesa());

        Despesa despesa = Despesa.builder()
                .fornecedor(fornecedor)
                .tipoDespesa(tipoDespesa)
                .descricao(dto.descricao())
                .valorGasto(dto.valorGasto())
                .dataDespesa(OffsetDateTime.now())
                .build();

        despesa.setSyncStatus("PENDING_CREATE");

        Despesa salva = despesaRepository.save(despesa);

        return DespesaResponseDTO.from(salva);
    }

    @Transactional
    public DespesaResponseDTO editar(Long id, DespesaRequestDTO dto) {
        Despesa despesa = buscarEntidadePorId(id);

        Fornecedor fornecedor = resolverFornecedor(dto.idFornecedor());
        TipoDespesa tipoDespesa = resolverTipoDespesa(dto.idTipoDespesa());

        despesa.setFornecedor(fornecedor);
        despesa.setTipoDespesa(tipoDespesa);
        despesa.setDescricao(dto.descricao());
        despesa.setValorGasto(dto.valorGasto());

        marcarComoPendenteUpdate(despesa);

        Despesa atualizada = despesaRepository.save(despesa);

        return DespesaResponseDTO.from(atualizada);
    }

@Transactional
public void excluir(Long id) {
    excluir(id, null);
}

@Transactional
public void excluir(Long id, DespesaExclusaoRequestDTO dto) {
    Despesa despesa = buscarEntidadePorId(id);

    despesa.setDeleted(true);
    despesa.setMotivoExclusao(
            dto != null &&
            dto.motivoExclusao() != null &&
            !dto.motivoExclusao().isBlank()
                    ? dto.motivoExclusao().trim()
                    : null
    );

    despesa.setSyncStatus("PENDING_DELETE");

    Long versaoAtual = despesa.getVersion() == null ? 0L : despesa.getVersion();
    despesa.setVersion(versaoAtual + 1);

    despesaRepository.save(despesa);
}

    // ══════════════════════════════════════════════════════════════════════
    // TIPOS DE DESPESA
    // ══════════════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public List<TipoDespesaResponseDTO> listarTiposDespesa() {
        return tipoDespesaRepository.findByDeletedFalseOrderByNomeDespesaAsc()
                .stream()
                .map(TipoDespesaResponseDTO::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public TipoDespesaResponseDTO buscarTipoDespesaPorId(Long id) {
        TipoDespesa tipoDespesa = buscarTipoDespesaEntidadePorId(id);
        return TipoDespesaResponseDTO.from(tipoDespesa);
    }

    @Transactional
    public TipoDespesaResponseDTO criarTipoDespesa(TipoDespesaRequestDTO dto) {
        TipoDespesa tipoDespesa = TipoDespesa.builder()
                .nomeDespesa(dto.nomeDespesa())
                .descricao(dto.descricao())
                .build();

        tipoDespesa.setSyncStatus("PENDING_CREATE");

        TipoDespesa salvo = tipoDespesaRepository.save(tipoDespesa);

        return TipoDespesaResponseDTO.from(salvo);
    }

    @Transactional
    public TipoDespesaResponseDTO editarTipoDespesa(
            Long id,
            TipoDespesaRequestDTO dto
    ) {
        TipoDespesa tipoDespesa = buscarTipoDespesaEntidadePorId(id);

        tipoDespesa.setNomeDespesa(dto.nomeDespesa());
        tipoDespesa.setDescricao(dto.descricao());

        if (!"PENDING_CREATE".equalsIgnoreCase(tipoDespesa.getSyncStatus())) {
            tipoDespesa.setSyncStatus("PENDING_UPDATE");
        }

        TipoDespesa atualizado = tipoDespesaRepository.save(tipoDespesa);

        return TipoDespesaResponseDTO.from(atualizado);
    }

    @Transactional
    public void excluirTipoDespesa(Long id) {
        TipoDespesa tipoDespesa = buscarTipoDespesaEntidadePorId(id);

        tipoDespesa.setDeleted(true);
        tipoDespesa.setSyncStatus("PENDING_DELETE");

        tipoDespesaRepository.save(tipoDespesa);
    }

    // ══════════════════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════════════════

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

    private TipoDespesa resolverTipoDespesa(Long idTipoDespesa) {
        if (idTipoDespesa == null) {
            throw new RuntimeException("O tipo de despesa é obrigatório");
        }

        return tipoDespesaRepository.findById(idTipoDespesa)
                .filter(t -> !t.isDeleted())
                .orElseThrow(() -> new RuntimeException(
                        "Tipo de despesa não encontrado com id: " + idTipoDespesa
                ));
    }

    private TipoDespesa buscarTipoDespesaEntidadePorId(Long id) {
        return tipoDespesaRepository.findById(id)
                .filter(t -> !t.isDeleted())
                .orElseThrow(() -> new RuntimeException(
                        "Tipo de despesa não encontrado com id: " + id
                ));
    }

    private void marcarComoPendenteUpdate(Despesa despesa) {
        if (!"PENDING_CREATE".equalsIgnoreCase(despesa.getSyncStatus())) {
            despesa.setSyncStatus("PENDING_UPDATE");
        }
    }
}