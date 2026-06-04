package com.stechengenharia.pdv_backend.produto.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Objects;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProdutoMarcaId implements Serializable {
    
    private Integer idProduto;
    private Integer idMarca;
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ProdutoMarcaId that = (ProdutoMarcaId) o;
        return Objects.equals(idProduto, that.idProduto) && 
               Objects.equals(idMarca, that.idMarca);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(idProduto, idMarca);
    }
}