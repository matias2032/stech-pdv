package com.stechengenharia.pdv_backend.categoria.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Entity
@Table(name = "categoria_marca")
@Data
@NoArgsConstructor
@AllArgsConstructor
@IdClass(CategoriaMarcaId.class)
public class CategoriaMarca implements Serializable {
    
    @Id
    @Column(name = "id_categoria")
    private Integer idCategoria;
    
    @Id
    @Column(name = "id_marca")
    private Integer idMarca;
}