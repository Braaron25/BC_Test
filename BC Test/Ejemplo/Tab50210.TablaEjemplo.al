table 50210 TablaEjemplo
{
    Caption = 'TablaEjemplo';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Codigo; Integer)
        {
            Caption = 'Codigo';
        }
        field(2; Nombre; Text[50])
        {
            Caption = 'Nombre';
        }
        field(3; Descripcion; Text[200])
        {
            Caption = 'Descripcion';
        }
    }
    keys
    {
        key(PK; Codigo)
        {
            Clustered = true;
        }
    }
}
