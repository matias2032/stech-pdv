package com.stechengenharia.pdv_backend.cliente.entity;
import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

@Entity
@Table(name = "cliente")
@Getter
@Setter
@NoArgsConstructor    // ← ADICIONE ISTO para permitir o "new Cliente()"
@AllArgsConstructor   // ← ADICIONE ISTO (boa prática e exigido pelo NoArgsConstructor + SuperBuilder)
@SuperBuilder      
public class Cliente extends AuditableEntity {  // ← herda os campos de auditoria

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cliente")
    // @Setter(AccessLevel.NONE) // Boa prática: impede alterar o ID manualmente
    private Long id;

    @Column(length = 250)
    private String nome;

    @Column(length = 250)
    private String apelido;

    @Column(unique = true, length = 250)
    private String email;

    @Column(unique = true, length = 250)
    private String nuit;

    @Column(unique = true, length = 250)
    private String contacto;

    @Column(unique = true, length = 250)
    private String morada;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_perfil_cliente", nullable = false)
    private PerfilCliente perfil;
}