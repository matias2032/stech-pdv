package com.stechengenharia.pdv_backend.cliente.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "perfil_cliente")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PerfilCliente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_perfil_cliente")
    private Long id;

    @Column(name = "nome_perfil_cliente", nullable = false, length = 100)
    private String nome;

    private String descricao;
}