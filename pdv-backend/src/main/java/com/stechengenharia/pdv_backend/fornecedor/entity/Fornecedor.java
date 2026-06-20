package com.stechengenharia.pdv_backend.fornecedor.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

@Entity
@Table(name = "fornecedor")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class Fornecedor extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_fornecedor")
    private Long id;

    @Column(length = 250)
    private String nome;

    @Column(unique = true, length = 250)
    private String email;

    @Column(unique = true, length = 250)
    private String nuit;

    @Column(unique = true, nullable = false, length = 250)
    private String contacto;

    @Column(length = 250)
    private String morada;
}