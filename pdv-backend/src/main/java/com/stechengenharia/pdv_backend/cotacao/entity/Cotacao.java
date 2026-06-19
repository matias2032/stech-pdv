package com.stechengenharia.pdv_backend.cotacao.entity;

import com.stechengenharia.pdv_backend.cliente.entity.Cliente;
import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import com.stechengenharia.pdv_backend.pedido.entity.Pedido;
import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "cotacao")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class Cotacao extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cotacao")
    private Long id;

    @Column(name = "referencia", nullable = false, unique = true, length = 50)
    private String referencia;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cliente")
    private Cliente cliente;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;

    @Column(name = "status_cotacao", nullable = false, length = 20)
    private String statusCotacao = "ABERTA";

    @Column(name = "total", nullable = false, precision = 12, scale = 2)
    private BigDecimal total = BigDecimal.ZERO;

    @Column(name = "validade_ate")
    private LocalDate validadeAte;

    @Column(name = "observacoes", columnDefinition = "text")
    private String observacoes;

    @Column(name = "nome_cliente_singular", length = 150)
private String nomeClienteSingular;

@Column(name = "apelido_cliente_singular", length = 150)
private String apelidoClienteSingular;

    // Preenchido apenas após conversão
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_pedido_convertido")
    private Pedido pedidoConvertido;

@OneToMany(mappedBy = "cotacao", cascade = CascadeType.ALL, orphanRemoval = true)
@Builder.Default
private Set<CotacaoItemProduto> itensProduto = new HashSet<>();

@OneToMany(mappedBy = "cotacao", cascade = CascadeType.ALL, orphanRemoval = true)
@Builder.Default
private Set<CotacaoItemServico> itensServico = new HashSet<>();

    // ── Helpers de negócio ────────────────────────────────────────────

    public void recalcularTotal() {
        BigDecimal totalProdutos = itensProduto.stream()
                .map(CotacaoItemProduto::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalServicos = itensServico.stream()
                .map(CotacaoItemServico::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        this.total = totalProdutos.add(totalServicos);
    }

public boolean isEditavel() {
    return "ABERTA".equals(this.statusCotacao);
}

public boolean isPronta() {
    return "PRONTA".equals(this.statusCotacao);
}

public boolean isConvertivel() {
    return "PRONTA".equals(this.statusCotacao);
}

    public boolean temItens() {
        return !itensProduto.isEmpty() || !itensServico.isEmpty();
    }
}