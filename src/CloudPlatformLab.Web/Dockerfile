# Build and publish stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["src/CloudPlatformLab.Web/CloudPlatformLab.Web.csproj", "src/CloudPlatformLab.Web/"]
COPY ["src/CloudPlatformLab.Application/CloudPlatformLab.Application.csproj", "src/CloudPlatformLab.Application/"]

RUN dotnet restore "src/CloudPlatformLab.Web/CloudPlatformLab.Web.csproj"

COPY . .

WORKDIR "/src/src/CloudPlatformLab.Web"
RUN dotnet publish "CloudPlatformLab.Web.csproj" -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080
ENV ASPNETCORE_HTTP_PORTS=8080

ENTRYPOINT ["dotnet", "CloudPlatformLab.Web.dll"]