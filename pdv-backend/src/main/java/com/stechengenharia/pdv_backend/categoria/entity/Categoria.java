package com.stechengenharia.pdv_backend.categoria.entity;

import jakarta.persistence.*;
import lombok.NoArgsConstructor;
import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "categoria")
@Getter
@Setter
@NoArgsConstructor
public class Categoria extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_categoria")
    private Integer idCategoria;

    @Column(name = "nome_categoria", nullable = false, length = 100)
    private String nomeCategoria;

    @Column(name = "descricao", columnDefinition = "TEXT")
    private String descricao;
}