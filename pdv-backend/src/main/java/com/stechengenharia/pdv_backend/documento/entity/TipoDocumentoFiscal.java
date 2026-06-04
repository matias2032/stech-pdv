package com.stechengenharia.pdv_backend.documento.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "tipo_documento_fiscal")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TipoDocumentoFiscal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_tipo_doc")
    private Integer id;

    @Column(nullable = false, unique = true, length = 10)
    private String codigo;

    @Column(nullable = false, length = 100)
    private String nome;

    @Column(nullable = false, unique = true, length = 10)
    private String prefixo;

    @Column(name = "seq_name", nullable = false, unique = true, length = 60)
    private String seqName;
}