use MooseX::Declare;

class Pod::MetaFusion::Renderer::Class 
    extends Pod::MetaFusion::Renderer 
    with    Pod::MetaFusion::Renderer::WithAttributes
    with    Pod::MetaFusion::Renderer::WithMethods
    with    Pod::MetaFusion::Renderer::WithRoles
    with    Pod::MetaFusion::Renderer::WithInheritance
    with    Pod::MetaFusion::Renderer::WithName {

    method name_field { 'class' }
}
