FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["Dub/Dub.csproj", "Dub/"]
RUN dotnet restore "Dub/Dub.csproj"
COPY . .
WORKDIR "/src/Dub"
RUN dotnet build "Dub.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Dub.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Dub.dll"]
