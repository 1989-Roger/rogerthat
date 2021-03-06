#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#include 'TopConn.ch'

/*=================================================================

Fonte em MVC para manuten��o de tipos de aumento salarial
N�o ser� poss�vel excluir registros padr�o ou 
que estejam na tabela SR7 (cabe�alho de hist�rico salarial)

@author     Roger Mathias da Silva
@since      10/09/2020
@param
@version    P12
@return
@project
@client    

/==================================================================*/

User Function SX541M()

   Local oBrowse 
 
   // Default lAuto := .F.
   
oBrowse := FWMBrowse():New()
oBrowse:SetAlias('SX5')
oBrowse:SetOnlyFields({'X5_FILIAL','X5_TABELA','X5_CHAVE','X5_DESCRI'}) //CAMPOS QUE SER�O APRESENTADOS NO BROWSE
oBrowse:SetDescription("Tipos de Aumento Salarial") //TITULO DO BROWSE
oBrowse:AddLegend( "RTRIM(X5_CHAVE)$('001/002/003/EXO/APO/NOM') .AND. X5_TABELA='41'", "RED", "Padrao" )
oBrowse:AddLegend( "!(RTRIM(X5_CHAVE) $ ('001/002/003/EXO/APO/NOM')) .AND. X5_TABELA='41'", "BLUE" , "Customizado" )
oBrowse:SetFilterDefault( "X5_TABELA=='41'" ) 

//oBrowse:DisableDetails()

oBrowse:SetMenuDef( 'SX541M' )

oBrowse:Activate()
  

Return oBrowse

//=====================================================================================

Static Function MenuDef() 


   Local aRotina := {} 

ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.SX541M' OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.SX541M' OPERATION 3 ACCESS 0 
ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.SX541M' OPERATION 4 ACCESS 0 
ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.SX541M' OPERATION 5 ACCESS 0

Return (aRotina)

//============================================================

 Static Function ModelDef()

   // Cria as estruturas a serem usadas no Modelo de Dados
   Local oStruSX5 := FWFormStruct( 1, 'SX5', { |cCampo| SX5STRU(cCampo) }) //1 = modelo de dados e 2 = view, ir� verificar os campos e retornar apenas os que se necessita

   Local oModel // Modelo de dados constru��o

   //oStruSX5:RemoveField(SX5->X5_DESCENG) //remover campo
   //oStruSX5:RemoveField(SX5->X5_DESCSPA)


oStruSX5:SetProperty('X5_TABELA', MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD, '41'))   
oStruSX5:SetProperty( 'X5_TABELA' ,MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN , ".F.")) // N�o poder� alterar em nenhum momento, pois e da tabela padr�o 41 na SX5                     
oStruSX5:SetProperty( 'X5_CHAVE' , MODEL_FIELD_WHEN,{||  INCLUI}) //s� permitir� edi��o no campo chave quando for inclus�o
oStruSX5:SetProperty( 'X5_CHAVE' , MODEL_FIELD_TAMANHO , 3 ) //fixar tamanho do campo com 3
oStruSX5:SetProperty( 'X5_CHAVE' , MODEL_FIELD_VALID ,FwBuildFeature( STRUCT_FEATURE_VALID, "U_VLDSX541()" )) //Verifica se o tamnho do campo � igual a 3  

// Cria o objeto do Modelo de Dados
oModel   	:= MPFormModel():New( 'CGPE1MD'/*sempre desse tamanho a chamada*/, /*bPreValidacao*/,{|oMdl| MDMVlPos(oMdl) }/*bPosVld*/, /*bCommit*/ , /*bCancel*/ )//


oModel:AddFields( 'SX5MASTER', /*cOwner*/, oStruSX5 ) // Adiciona ao modelo um componente de formulário
oModel:GetModel( 'SX5MASTER' ):SetDescription( 'Tipos de Aumento' ) // Adiciona a descrição dos Componentes do Modelo de Dados


oModel:SetPrimaryKey({"X5_TABELA","X5_CHAVE"})
oModel:SetDescription( 'Tabela Tipos de Aumento Salarial' ) // Adiciona a descri��o do Modelo de Dados

Return oModel


//=============================================

Static Function ViewDef()

   Local oModel := FWLoadModel('SX541M')  // // Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
   Local oStruSX5 := FWFormStruct( 2, 'SX5',  { |cCampo| SX5STRU(cCampo) } ) // Cria as estruturas a serem usadas na View
   Local oView    // Interface de visualização constru�da
   //Local oModelSX5 := oModel:GetModel( 'SX5MASTER' ) 


oView := FWFormView():New() // Cria o objeto de View
oView:SetModel( oModel ) // Define qual Modelo de dados será utilizado

oView:AddField( 'VIEW_SX5', oStruSX5, 'SX5MASTER' ) // Adiciona no nosso View um controle do tipo formul�rio (antiga Enchoice)

oStruSX5:RemoveField('x5_DESCENG') //remover campo  
oStruSX5:RemoveField('X5_DESCSPA')

//Adiciona no nosso View um controle do tipo Grid (antiga Getdados
 //======================================================//                        
oView:CreateHorizontalBox( 'SUPERIOR', 100 ) // Cria um "box" horizontal para receber cada elemento da view

oView:SetOwnerView( 'VIEW_SX5', 'SUPERIOR' ) // Relaciona o identificador (ID) da View com o "box" para exibi��o



Return oView // Retorna o objeto de View criado

/*=======================================================

Valida��o ap�s exclus�o de registro, n�o deixar� excluir registros que est�o na SR7,
nem os registros padr�o ('001/002/003/EXO/APO/NOM')

/====================================================*/
Static Function MDMVlPos( oModel )    
   Local nOperation := oModel:GetOperation()
   Local lRet := .T.      
   Local cQuery    := ""
   Local aArea := SR7->(GetArea())
   Local aDados   :=  ""  //{}
   Local cErro

  
   If nOperation == 5

      cQuery := "SELECT DISTINCT R7_TIPO FROM "+ RetSqlName("SR7") + " SR7 WHERE SR7.D_E_L_E_T_='' "

      TCQuery cQuery New Alias "XSR7"

      While !XSR7->(Eof())
         
         aDados += XSR7->R7_TIPO +"/"
         XSR7->(DbSkip())  
      EndDo

      XSR7->(DbCloseArea())
      RestArea(aArea)
       If  (RTRIM(SX5->X5_CHAVE) $ aDados )  
            cErro :=  "Registro utilizado no hist�rico, n�o � permitido a exclus�o ."   
            lRet := .F.
         EndIf
      If RTRIM(SX5->X5_CHAVE)$('001/002/003/EXO/APO/NOM')
            cErro :="N�o � permitida exclus�o de um registro Padr�o."
            lRet := .F.
      EndIf

      

      If lRet == .F.
         HELP( ,, "HELP","MDMVlPos",cErro, 1, 0)  
      EndIf

      
   EndIf
   RestArea(aArea)
Return( lRet )


/*============================================================

Montagem da estrutura, ir� remover campos em espanhol e ingl�s da tela
na hora da exclus�o/inclusao/altera�ao/visualiza��o

/===========================================================*/


Static Function SX5STRU( cCampo ) 

   Local lRet := .T. 

 
If cCampo $ 'X5_DESCENG/X5_DESCSPA' 
   lRet := .F. 
EndIf 

Return lRet

//============================================
//
// Validar tamanho do campo
//
//===================================
User Function  VLDSX541()

   Local _Valida  := .T.
   Local _Ni := 0	 
   Local _nLen := 0

   IF len(ALLTRIM(M->X5_CHAVE)) < 3

      MSGSTOP("O campo deve possuir 3 caracteres, favor ajustar")
	   _Valida := .F. 
   Endif

   IF dbSeek(xFilial("SX5") + '41'+ M->X5_CHAVE)
      MSGSTOP("C�digo j� existe na tabela, por favor mudar")
	   _Valida := .F. 
   Endif

Return(_Valida)


