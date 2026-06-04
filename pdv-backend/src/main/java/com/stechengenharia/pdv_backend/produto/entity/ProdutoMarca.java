package com.stechengenharia.pdv_backend.produto.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Entity
@Table(name = "produto_marca")
@Data
@NoArgsConstructor
@AllArgsConstructor
@IdClass(ProdutoMarcaId.class)
public class ProdutoMarca implements Serializable {
    
    @Id
    @Column(name = "id_produto")
    private Integer idProduto;
    
    @Id
    @Column(name = "id_marca")
    private Integer idMarca;
}