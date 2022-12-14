#version 430 
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoords;
//vec3 smoothedNormals[20][]; -> not legal

layout(binding = 7, std430) buffer smoothedNormalsBuffer  
{
    vec4 smoothedNormals[];
};

out vec2 TexCoords;

//out vec3 col;
out float col;

struct Light {
    vec3 position;
    vec3 diffuse;
};

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
//"global" lighting

uniform Light light;

uniform float clampCoef;
uniform int scales;
uniform int size;
uniform float contribution[20];
uniform float ambient;

void main() {
    gl_Position = projection * view *  model * vec4(aPos, 1.0f);
    vec3 FragPos = vec3(model * vec4(aPos, 1.0f)); 
    vec3 Normal = normalize(mat3(transpose(inverse(model))) * aNormal);
    //vec3 Normal = normalize(aNormal);
    //vec3 lightGlobal = normalize(light.position - FragPos);
    vec4 lightGlobal = vec4(normalize(light.position - FragPos),0.0);
    

    TexCoords = aTexCoords;
    //vec3 textureColor = vec3(0.95,0.95,0.95);

    //vec3 light_ip1;
    //vec3 normal_i;
    //vec3 normal_ip1;
    vec4 light_ip1;
    vec4 normal_i;
    vec4 normal_ip1;
    
    float detailTerms=0.0;
    float c_i=0.0;
    for(int i=0;i<scales;i++){
        //load smoothed normals
        normal_i=normalize(smoothedNormals[gl_VertexID+i*size]);
        normal_ip1=normalize(smoothedNormals[gl_VertexID+(i+1)*size]);

        //tangent plane projection
        //light_ip1 = (-1.0)*normalize(lightGlobal-dot(lightGlobal,normal_ip1)*normal_ip1);
        light_ip1 = normalize(lightGlobal-dot(lightGlobal,normal_ip1)*normal_ip1);
        c_i = clamp(clampCoef*dot(normal_i,light_ip1),-1.0,1.0);
        detailTerms+=contribution[i]*c_i;
    }
    //actual implementation    
    col=(ambient + 0.5*(contribution[scales]*dot(smoothedNormals[gl_VertexID+scales*size],lightGlobal)+detailTerms));
    
    //check normals, and indexing   
    //col=dot(normalize(smoothedNormals[gl_VertexID + size*(scales-1)]),lightGlobal)*vec4(textureColor,0.0);

    //check clampCoef
    //col = 0.1*clampCoef*vec4(textureColor,0.0);
    
    //check detail terms
    //col= 2*detailTerms*vec4(textureColor,0.0);

    //check contribution uniform
    //col = 2*contribution[0]*vec4(textureColor,0.0);

    //check c_i
    /*
    int i=scales-1;
    normal_i=normalize(smoothedNormals[gl_VertexID+i*size]);
    normal_ip1=normalize(smoothedNormals[gl_VertexID+(i+1)*size]);
        
    light_ip1=normalize(lightGlobal-dot(lightGlobal,normal_ip1)*normal_ip1);
    c_i = clamp(clampCoef*dot(normal_i,light_ip1),-1.0,1.0);
    col = (0.5+0.5*c_i)*vec4(textureColor,0.0);
    */
}
