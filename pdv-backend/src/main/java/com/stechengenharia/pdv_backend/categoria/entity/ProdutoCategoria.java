package com.stechengenharia.pdv_backend.categoria.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Entity
@Table(name = "produto_categoria")
@Data
@NoArgsConstructor
@AllArgsConstructor
@IdClass(ProdutoCategoriaId.class)
public class ProdutoCategoria implements Serializable {
    
    @Id
    @Column(name = "id_produto")
    private Integer idProduto;
    
    @Id
    @Column(name = "id_categoria")
    private Integer idCategoria;
}