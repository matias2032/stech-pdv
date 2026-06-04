package com.stechengenharia.pdv_backend.marca.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;

import jakarta.persistence.*;
import lombok.NoArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "marca")
@Getter
@Setter
@NoArgsConstructor
public class Marca extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_marca")
    private Integer idMarca;

    @Column(name = "nome_marca", nullable = false, length = 100)
    private String nomeMarca;
}